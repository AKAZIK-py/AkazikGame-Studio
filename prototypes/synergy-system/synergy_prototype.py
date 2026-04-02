#!/usr/bin/env python3
# PROTOTYPE - NOT FOR PRODUCTION
# Question: 羁绊检测和效果应用是否正确工作？特殊羁绊（狍子、EOE姐妹、单挂）是否能正确触发？
# Date: 2026-03-28
"""
羁绊系统原型 - 验证核心逻辑 (Python版本，无需Godot)

运行: python3 synergy_prototype.py
"""

import sys

# ============================================================
# 数据类
# ============================================================

class CharacterData:
    def __init__(self, id: str, name: str, attack: float, health: float, tags: list):
        self.id = id
        self.display_name = name
        self.base_attack = attack
        self.base_health = health
        self.synergy_tags = tags
        self.final_attack = attack
        self.final_health = health

    def __repr__(self):
        return f"Character({self.display_name}, ATK:{self.base_attack}, HP:{self.base_health}, Tags:{self.synergy_tags})"

class SynergyData:
    def __init__(self, id: str, name: str, synergy_type: str, thresholds: list, effect: dict):
        self.id = id
        self.display_name = name
        self.type = synergy_type
        self.thresholds = thresholds
        self.effect = effect

# ============================================================
# 数据注册表
# ============================================================

class CharacterRegistry:
    def __init__(self):
        self._characters = {
            # 1费角色
            "xiao_ke": CharacterData("xiao_ke", "小可", 45, 550, ["vr", "singer"]),
            "lu_zao": CharacterData("lu_zao", "露早", 45, 550, ["singer", "eoe_sisters"]),
            "you_en": CharacterData("you_en", "柚恩", 48, 520, ["singer", "eoe_sisters"]),
            # 2费角色
            "hirro": CharacterData("hirro", "hirro", 55, 650, ["gunner"]),
            "xue_gao": CharacterData("xue_gao", "雪糕", 52, 620, ["gunner", "tang"]),
            # 3费角色
            "azi": CharacterData("azi", "阿梓", 60, 700, ["vr", "singer", "tang"]),
            "tian_dou": CharacterData("tian_dou", "恬豆", 58, 720, ["idol", "vr"]),
            "dong_ai_li": CharacterData("dong_ai_li", "东爱璃", 55, 680, ["wildcard"]),
            # 4费角色
            "qi_hai": CharacterData("qi_hai", "七海", 70, 800, ["vr", "idol"]),
        }

    def get_character(self, id: str) -> CharacterData:
        return self._characters.get(id)

class SynergyRegistry:
    def __init__(self):
        self._synergies = {
            "vr": SynergyData("vr", "VR", "normal", [2, 4], {"type": "stat_bonus", "stat": "attack", "values": [0.15, 0.30]}),
            "idol": SynergyData("idol", "偶像", "normal", [2, 4, 5], {"type": "stat_bonus", "stat": "health", "values": [0.12, 0.25, 0.40]}),
            "singer": SynergyData("singer", "歌手", "normal", [2, 4], {"type": "stat_bonus", "stat": "skill_damage", "values": [0.20, 0.40]}),
            "tang": SynergyData("tang", "糖", "normal", [2, 3], {"type": "stat_bonus", "stat": "attack_speed", "values": [0.15, 0.30]}),
            "gunner": SynergyData("gunner", "枪手", "normal", [2], {"type": "special", "effect": "extra_shot", "value": 0.35}),
            "eoe_sisters": SynergyData("eoe_sisters", "EOE姐妹", "combo", [2], {"type": "combo_boost", "attack_mult": 2.5, "health_mult": 2.0}),
            "wildcard": SynergyData("wildcard", "狍子", "wildcard", [1], {"type": "wildcard"}),
        }

    def get_synergy(self, id: str) -> SynergyData:
        return self._synergies.get(id)

# ============================================================
# 棋盘系统 (六边形坐标)
# ============================================================

class BoardSystem:
    def __init__(self):
        self._board = {}  # key: (q, r), value: CharacterData

    def clear(self):
        self._board.clear()

    def place_character(self, char: CharacterData, q: int, r: int):
        self._board[(q, r)] = char

    def get_character_at(self, q: int, r: int) -> CharacterData:
        return self._board.get((q, r))

    def get_all_characters(self) -> list:
        return list(self._board.values())

    def get_occupied_cells(self) -> list:
        return list(self._board.keys())

    def get_neighbors(self, q: int, r: int) -> list:
        """获取六边形邻居坐标"""
        directions = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
        return [(q + dq, r + dr) for dq, dr in directions]

    def is_isolated(self, q: int, r: int) -> bool:
        """检查位置是否孤立"""
        for nq, nr in self.get_neighbors(q, r):
            if (nq, nr) in self._board:
                return False
        return True

# ============================================================
# 羁绊检测系统
# ============================================================

class SynergyDetector:
    def __init__(self, synergy_registry: SynergyRegistry, board: BoardSystem):
        self._synergy_registry = synergy_registry
        self._board = board
        self._active_synergies = {}

    def detect_synergies(self) -> list:
        self._active_synergies.clear()

        # 统计每个羁绊的角色数量
        synergy_counts = {}
        wildcard_chars = []

        for char in self._board.get_all_characters():
            for tag in char.synergy_tags:
                if tag == "wildcard":
                    wildcard_chars.append(char)
                else:
                    synergy_counts[tag] = synergy_counts.get(tag, 0) + 1

        # 处理狍子 (万能羁绊)
        for synergy_id in list(synergy_counts.keys()):
            synergy = self._synergy_registry.get_synergy(synergy_id)
            if synergy and synergy.type == "normal":
                count = synergy_counts[synergy_id]
                thresholds = synergy.thresholds
                for threshold in thresholds:
                    if count < threshold and count + len(wildcard_chars) >= threshold:
                        count = threshold
                        break
                synergy_counts[synergy_id] = count

        # 检测激活的羁绊
        for synergy_id, count in synergy_counts.items():
            synergy = self._synergy_registry.get_synergy(synergy_id)
            if synergy is None:
                continue

            # 特殊处理组合羁绊
            if synergy.type == "combo":
                if self._check_combo_synergy(synergy_id):
                    self._active_synergies[synergy_id] = {"level": 1, "count": count}
            elif synergy.type == "normal":
                level = self._get_synergy_level(synergy_id, count)
                if level > 0:
                    self._active_synergies[synergy_id] = {"level": level, "count": count}

        return list(self._active_synergies.keys())

    def _check_combo_synergy(self, synergy_id: str) -> bool:
        """检查组合羁绊是否满足条件"""
        if synergy_id == "eoe_sisters":
            has_luzao = False
            has_youen = False
            for char in self._board.get_all_characters():
                if char.id == "lu_zao":
                    has_luzao = True
                if char.id == "you_en":
                    has_youen = True
            return has_luzao and has_youen
        return False

    def _get_synergy_level(self, synergy_id: str, count: int) -> int:
        synergy = self._synergy_registry.get_synergy(synergy_id)
        if synergy is None:
            return 0

        level = 0
        for i, threshold in enumerate(synergy.thresholds):
            if count >= threshold:
                level = i + 1
        return level

    def get_synergy_level(self, synergy_id: str) -> int:
        if synergy_id in self._active_synergies:
            return self._active_synergies[synergy_id]["level"]
        return 0

    def get_active_synergies(self) -> dict:
        return self._active_synergies

# ============================================================
# 羁绊效果系统
# ============================================================

class SynergyEffectSystem:
    def __init__(self, synergy_registry: SynergyRegistry):
        self._synergy_registry = synergy_registry

    def apply_synergy_effects(self, char: CharacterData, active_synergies: dict):
        """应用羁绊效果到角色"""
        # 重置最终属性
        char.final_attack = char.base_attack
        char.final_health = char.base_health

        # 先检查EOE姐妹强化
        if "eoe_sisters" in active_synergies:
            if char.id in ["lu_zao", "you_en"]:
                eoe_synergy = self._synergy_registry.get_synergy("eoe_sisters")
                char.final_attack *= eoe_synergy.effect["attack_mult"]
                char.final_health *= eoe_synergy.effect["health_mult"]

        # 应用普通羁绊效果
        for synergy_id, data in active_synergies.items():
            synergy = self._synergy_registry.get_synergy(synergy_id)
            if synergy is None or synergy.type != "normal":
                continue

            # 检查角色是否有这个羁绊标签
            if synergy_id not in char.synergy_tags:
                continue

            level = data["level"] - 1  # 0-indexed
            effect_value = synergy.effect["values"][level]

            stat = synergy.effect["stat"]
            if stat == "attack":
                char.final_attack *= (1 + effect_value)
            elif stat == "health":
                char.final_health *= (1 + effect_value)

    def apply_isolated_effect(self, char: CharacterData, is_isolated: bool):
        """应用单挂效果"""
        if is_isolated and char.id == "hirro":
            char.final_attack *= 1.4  # +40% 攻击
            char.final_health *= 1.3  # +30% 生命

# ============================================================
# 测试用例
# ============================================================

class TestRunner:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.results = []

    def assert_true(self, condition: bool, message: str):
        if condition:
            self.passed += 1
            self.results.append(f"  ✓ {message}")
        else:
            self.failed += 1
            self.results.append(f"  ✗ {message}")

    def print_results(self):
        print("-" * 50)
        for result in self.results:
            print(result)
        print("-" * 50)
        print(f"通过: {self.passed}, 失败: {self.failed}")

def test_vr_synergy(char_registry, board, detector, effect_system, test):
    print("\n### 测试1: VR羁绊 (2/4 阈值) ###")

    # 清空棋盘
    board.clear()

    # 放置1个VR角色
    board.place_character(char_registry.get_character("xiao_ke"), 0, 0)
    synergies = detector.detect_synergies()
    print(f"1个VR角色: 激活羁绊 {synergies}")
    test.assert_true("vr" not in synergies, "1个VR角色不应激活羁绊")

    # 放置第2个VR角色 (达到2人阈值)
    board.place_character(char_registry.get_character("azi"), 1, 0)
    synergies = detector.detect_synergies()
    level = detector.get_synergy_level("vr")
    print(f"2个VR角色: 激活羁绊 {synergies}, 等级 {level}")
    test.assert_true("vr" in synergies, "2个VR角色应该激活羁绊")
    test.assert_true(level == 1, "VR羁绊应为1级")

    # 应用效果
    azi = board.get_character_at(1, 0)
    base_attack = azi.base_attack
    effect_system.apply_synergy_effects(azi, detector.get_active_synergies())
    boost = (azi.final_attack / base_attack - 1) * 100
    print(f"阿梓: 基础攻击 {base_attack} → 最终攻击 {azi.final_attack:.1f} (+{boost:.0f}%)")
    test.assert_true(abs(azi.final_attack - base_attack * 1.15) < 0.1, "VR 1级应为攻击+15%")

    # 放置第4个VR角色 (达到4人阈值)
    board.place_character(char_registry.get_character("qi_hai"), 2, 0)
    board.place_character(char_registry.get_character("tian_dou"), 3, 0)
    synergies = detector.detect_synergies()
    level = detector.get_synergy_level("vr")
    print(f"4个VR角色: 激活羁绊 {synergies}, 等级 {level}")
    test.assert_true(level == 2, "VR羁绊应为2级")

def test_eoe_synergy(char_registry, board, detector, effect_system, test):
    print("\n### 测试2: EOE姐妹 (组合羁绊) ###")

    # 清空棋盘
    board.clear()

    # 只放置露早
    board.place_character(char_registry.get_character("lu_zao"), 0, 0)
    synergies = detector.detect_synergies()
    print(f"只有露早: 激活羁绊 {synergies}")
    test.assert_true("eoe_sisters" not in synergies, "只有露早不应激活EOE姐妹")

    # 放置柚恩
    board.place_character(char_registry.get_character("you_en"), 1, 0)
    synergies = detector.detect_synergies()
    print(f"露早+柚恩: 激活羁绊 {synergies}")
    test.assert_true("eoe_sisters" in synergies, "露早+柚恩应该激活EOE姐妹")

    # 验证强化效果
    lu_zao = board.get_character_at(0, 0)
    base_attack = lu_zao.base_attack
    effect_system.apply_synergy_effects(lu_zao, detector.get_active_synergies())
    mult = lu_zao.final_attack / base_attack
    print(f"露早: 基础攻击 {base_attack} → 最终攻击 {lu_zao.final_attack:.1f} (强化倍率 {mult:.1f}x)")
    test.assert_true(abs(lu_zao.final_attack - base_attack * 2.5) < 0.1, "EOE强化效果应为2.5倍攻击")

def test_wildcard_synergy(char_registry, board, detector, effect_system, test):
    print("\n### 测试3: 狍子 (万能羁绊) ###")

    # 清空棋盘
    board.clear()

    # 放置东爱璃 (狍子)
    board.place_character(char_registry.get_character("dong_ai_li"), 0, 0)
    synergies = detector.detect_synergies()
    print(f"只有东爱璃: 激活羁绊 {synergies}")
    test.assert_true("wildcard" not in synergies, "狍子不提供独立效果")

    # 添加1个VR角色 + 东爱璃 = VR(2)
    board.place_character(char_registry.get_character("xiao_ke"), 1, 0)
    synergies = detector.detect_synergies()
    level = detector.get_synergy_level("vr")
    print(f"小可+东爱璃: 激活羁绊 {synergies}, VR等级 {level}")
    test.assert_true("vr" in synergies, "狍子应该计入VR羁绊")
    test.assert_true(level == 1, "VR羁绊应为1级")

    # 添加1个糖角色 + 东爱璃 = 糖(2)
    board.clear()
    board.place_character(char_registry.get_character("xue_gao"), 0, 0)
    board.place_character(char_registry.get_character("dong_ai_li"), 1, 0)
    synergies = detector.detect_synergies()
    level = detector.get_synergy_level("tang")
    print(f"雪糕+东爱璃: 激活羁绊 {synergies}, 糖等级 {level}")
    test.assert_true("tang" in synergies, "狍子应该计入糖羁绊")

def test_isolated_effect(char_registry, board, detector, effect_system, test):
    print("\n### 测试4: 单挂效果 (位置效果) ###")

    # 清空棋盘
    board.clear()

    # 放置hirro在孤立位置
    board.place_character(char_registry.get_character("hirro"), 5, 5)
    is_isolated = board.is_isolated(5, 5)
    print(f"hirro单独放置: 孤立 {is_isolated}")
    test.assert_true(is_isolated, "hirro单独放置应该是孤立的")

    # 应用单挂效果
    hirro = board.get_character_at(5, 5)
    base_attack = hirro.base_attack
    base_health = hirro.base_health
    effect_system.apply_isolated_effect(hirro, is_isolated)
    print(f"hirro: 攻击 {base_attack} → {hirro.final_attack:.1f}, 生命 {base_health} → {hirro.final_health:.1f}")
    test.assert_true(abs(hirro.final_attack - base_attack * 1.4) < 0.1, "单挂攻击加成应为40%")
    test.assert_true(abs(hirro.final_health - base_health * 1.3) < 0.1, "单挂生命加成应为30%")

    # 在旁边放置另一个角色
    board.place_character(char_registry.get_character("xiao_ke"), 6, 5)
    is_isolated = board.is_isolated(5, 5)
    print(f"hirro旁边有棋子: 孤立 {is_isolated}")
    test.assert_true(not is_isolated, "hirro旁边有棋子不应再孤立")

    # 重新计算 (重置)
    hirro.final_attack = hirro.base_attack
    hirro.final_health = hirro.base_health
    effect_system.apply_isolated_effect(hirro, is_isolated)
    print(f"hirro: 攻击 {base_attack * 1.4:.1f} → {hirro.final_attack:.1f} (效果消失)")
    test.assert_true(abs(hirro.final_attack - base_attack) < 0.1, "单挂效果应消失")

def test_multi_synergy(char_registry, board, detector, effect_system, test):
    print("\n### 测试5: 多羁绊叠加 ###")

    # 清空棋盘
    board.clear()

    # 阿梓有 VR + 歌手 + 糖 三个羁绊标签
    board.place_character(char_registry.get_character("azi"), 0, 0)
    board.place_character(char_registry.get_character("xiao_ke"), 1, 0)   # VR(2)
    board.place_character(char_registry.get_character("lu_zao"), 2, 0)   # 歌手(2)
    board.place_character(char_registry.get_character("xue_gao"), 3, 0)  # 糖(2)

    synergies = detector.detect_synergies()
    print(f"场上羁绊: {synergies}")

    # 应用多羁绊效果
    azi = board.get_character_at(0, 0)
    base_attack = azi.base_attack
    effect_system.apply_synergy_effects(azi, detector.get_active_synergies())
    print(f"阿梓: 基础攻击 {base_attack} → 最终攻击 {azi.final_attack:.1f}")

    # VR(攻击+15%)
    expected = base_attack * 1.15
    print(f"预期攻击 (VR+15%): {expected:.1f}")
    test.assert_true(abs(azi.final_attack - expected) < 0.1, "阿梓应该获得VR攻击加成")

# ============================================================
# 主程序
# ============================================================

def main():
    print("=" * 50)
    print("羁绊系统原型测试")
    print("=" * 50)

    # 初始化
    char_registry = CharacterRegistry()
    synergy_registry = SynergyRegistry()
    board = BoardSystem()
    detector = SynergyDetector(synergy_registry, board)
    effect_system = SynergyEffectSystem(synergy_registry)
    test = TestRunner()

    # 运行测试
    test_vr_synergy(char_registry, board, detector, effect_system, test)
    test_eoe_synergy(char_registry, board, detector, effect_system, test)
    test_wildcard_synergy(char_registry, board, detector, effect_system, test)
    test_isolated_effect(char_registry, board, detector, effect_system, test)
    test_multi_synergy(char_registry, board, detector, effect_system, test)

    # 打印结果
    test.print_results()

    return test.failed

if __name__ == "__main__":
    sys.exit(main())
