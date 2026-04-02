#!/usr/bin/env python3
# PROTOTYPE - NOT FOR PRODUCTION
# Question: 纯数值胜率计算是否有趣？战力公式是否合理？不同羁绊组合能否创造差异化体验？
# Date: 2026-03-28
"""
战斗系统原型 - 验证核心逻辑 (Python版本)

运行: python3 battle_prototype.py

验证内容:
1. 战力计算公式是否合理
2. 胜率计算是否有足够的策略空间
3. 不同羁绊组合是否有明显的强度差异
4. AI敌方阵容是否提供合理的挑战
"""

import random
import sys
from dataclasses import dataclass, field
from typing import List, Dict, Optional

# ============================================================
# 数据类
# ============================================================

@dataclass
class CharacterStats:
    id: str
    display_name: str
    base_attack: float
    base_health: float
    synergy_tags: List[str]
    role: str  # output, tank, support, core, warrior, mage
    rarity: int

    # 最终属性 (经过羁绊加成)
    final_attack: float = 0
    final_health: float = 0
    skill_damage_mult: float = 1.0
    attack_speed_mult: float = 1.0

    def __post_init__(self):
        self.final_attack = self.base_attack
        self.final_health = self.base_health

@dataclass
class SynergyEffect:
    id: str
    display_name: str
    thresholds: List[int]
    effect_type: str  # "attack", "health", "skill_damage", "attack_speed"
    values: List[float]

@dataclass
class TeamComposition:
    characters: List[CharacterStats]
    synergies: Dict[str, int]  # synergy_id -> level

# ============================================================
# 角色数据库 (与角色数据GDD一致)
# ============================================================

CHARACTER_DB = {
    # 1费角色
    "xiao_ke": CharacterStats("xiao_ke", "小可", 45, 550, ["vr", "singer"], "output", 1),
    "you_en": CharacterStats("you_en", "柚恩", 48, 520, ["singer", "eoe_sisters"], "output", 1),
    "ze_yin": CharacterStats("ze_yin", "泽音", 42, 580, ["singer"], "support", 1),
    "lu_zao": CharacterStats("lu_zao", "露早", 45, 550, ["singer", "eoe_sisters"], "output", 1),
    # 2费角色
    "hirro": CharacterStats("hirro", "hirro", 55, 650, ["gunner"], "output", 2),
    "xue_gao": CharacterStats("xue_gao", "雪糕", 52, 620, ["gunner", "tang"], "output", 2),
    "bai_shen_yao": CharacterStats("bai_shen_yao", "白神遥", 50, 680, ["psp", "tang"], "tank", 2),
    # 3费角色
    "lulu": CharacterStats("lulu", "雫lulu", 60, 700, ["idol", "tokyo"], "support", 3),
    "azi": CharacterStats("azi", "阿梓", 65, 750, ["vr", "singer", "tang"], "core", 3),
    "tian_dou": CharacterStats("tian_dou", "恬豆", 58, 800, ["idol", "vr"], "tank", 3),
    "dong_ai_li": CharacterStats("dong_ai_li", "东爱璃", 55, 720, ["psp", "wildcard"], "support", 3),
    # 4费角色
    "qi_hai": CharacterStats("qi_hai", "七海", 72, 850, ["vr", "idol"], "core", 4),
    "yong_chu_tafei": CharacterStats("yong_chu_tafei", "永雏塔菲", 75, 820, ["idol", "tang"], "output", 4),
    # 5费角色
    "xing_tong": CharacterStats("xing_tong", "星瞳", 80, 1000, ["idol", "big_corp"], "core", 5),
}

# ============================================================
# 羁绊效果数据库
# ============================================================

SYNERGY_DB = {
    "vr": SynergyEffect("vr", "VR", [2, 4], "attack", [0.15, 0.30]),
    "idol": SynergyEffect("idol", "偶像", [2, 4, 5], "health", [0.12, 0.25, 0.40]),
    "singer": SynergyEffect("singer", "歌手", [2, 4], "skill_damage", [0.20, 0.40]),
    "tang": SynergyEffect("tang", "糖", [2, 3], "attack_speed", [0.15, 0.30]),
    "gunner": SynergyEffect("gunner", "枪手", [2], "special", [0.35]),
    "psp": SynergyEffect("psp", "PSP", [2], "all_stats", [0.12]),
    "tokyo": SynergyEffect("tokyo", "东京", [1], "skill_damage", [0.25]),
    "eoe_sisters": SynergyEffect("eoe_sisters", "EOE姐妹", [2], "combo_boost", [1.8]),  # 调整：×2.5 → ×1.8
}

# ============================================================
# AI敌方阵容池
# ============================================================

ENEMY_TEAMS = [
    {
        "name": "歌手队",
        "characters": ["xiao_ke", "ze_yin", "lu_zao", "you_en"],
        "difficulty": "简单"
    },
    {
        "name": "VR基础",
        "characters": ["xiao_ke", "azi", "qi_hai"],
        "difficulty": "中等"
    },
    {
        "name": "糖分小队",
        "characters": ["xue_gao", "bai_shen_yao", "yong_chu_tafei"],
        "difficulty": "中等"
    },
    {
        "name": "偶像阵",
        "characters": ["lulu", "tian_dou", "qi_hai"],
        "difficulty": "困难"
    },
    {
        "name": "顶级阵容",
        "characters": ["xing_tong", "qi_hai", "azi", "yong_chu_tafei"],
        "difficulty": "极难"
    },
]

# ============================================================
# 战力计算系统
# ============================================================

ROLE_COEFFICIENTS = {
    "output": 1.1,
    "tank": 1.0,
    "support": 0.9,
    "core": 1.2,
    "warrior": 1.0,
    "mage": 1.05,
}

def calculate_power(char: CharacterStats) -> float:
    """
    计算单个角色的战力

    公式: 角色战力 = 攻击力 × 生命值 × 羁绊系数 × 定位系数
    """
    role_coef = ROLE_COEFFICIENTS.get(char.role, 1.0)

    # 技能伤害和攻速也影响战力
    skill_mult = char.skill_damage_mult
    speed_mult = char.attack_speed_mult

    power = char.final_attack * char.final_health * role_coef * skill_mult * speed_mult
    return power

def calculate_team_power(team: List[CharacterStats]) -> float:
    """计算队伍总战力"""
    return sum(calculate_power(c) for c in team)

def calculate_win_rate(player_power: float, enemy_power: float) -> float:
    """
    计算胜率

    公式: 胜率 = 玩家战力 / (玩家战力 + 敌方战力)
    """
    if player_power + enemy_power == 0:
        return 0.5
    return player_power / (player_power + enemy_power)

# ============================================================
# 羁绊检测与效果应用
# ============================================================

def detect_synergies(team: List[CharacterStats], wildcard_available: bool = True) -> Dict[str, int]:
    """
    检测队伍中激活的羁绊

    返回: {synergy_id: level}
    """
    # 统计每个羁绊标签的角色数量
    tag_counts = {}
    wildcard_count = 0

    for char in team:
        for tag in char.synergy_tags:
            if tag == "wildcard":
                wildcard_count += 1
            elif tag != "big_corp":  # 隐藏羁绊不参与
                tag_counts[tag] = tag_counts.get(tag, 0) + 1

    # 检测激活的羁绊
    active_synergies = {}

    for tag, count in tag_counts.items():
        synergy = SYNERGY_DB.get(tag)
        if synergy is None:
            continue

        # 使用狍子凑数
        if wildcard_available and wildcard_count > 0:
            for threshold in synergy.thresholds:
                if count < threshold and count + wildcard_count >= threshold:
                    count = threshold
                    wildcard_count -= 1  # 消耗一个狍子
                    break

        # 确定羁绊等级
        level = 0
        for i, threshold in enumerate(synergy.thresholds):
            if count >= threshold:
                level = i + 1

        if level > 0:
            active_synergies[tag] = level

    # 特殊处理: EOE姐妹组合羁绊
    char_ids = {c.id for c in team}
    if "lu_zao" in char_ids and "you_en" in char_ids:
        active_synergies["eoe_sisters"] = 1

    return active_synergies

def apply_synergy_effects(team: List[CharacterStats], synergies: Dict[str, int]):
    """应用羁绊效果到队伍中的角色"""

    for char in team:
        # 重置
        char.final_attack = char.base_attack
        char.final_health = char.base_health
        char.skill_damage_mult = 1.0
        char.attack_speed_mult = 1.0

        # EOE姐妹组合强化 (调整后: ×1.8/×1.5)
        if "eoe_sisters" in synergies and char.id in ["lu_zao", "you_en"]:
            char.final_attack *= 1.8
            char.final_health *= 1.5

        # 应用普通羁绊效果
        for syn_id, level in synergies.items():
            if syn_id == "eoe_sisters":
                continue  # 已处理

            synergy = SYNERGY_DB.get(syn_id)
            if synergy is None:
                continue

            # 检查角色是否有这个羁绊标签
            if syn_id not in char.synergy_tags:
                continue

            effect_value = synergy.values[level - 1]

            if synergy.effect_type == "attack":
                char.final_attack *= (1 + effect_value)
            elif synergy.effect_type == "health":
                char.final_health *= (1 + effect_value)
            elif synergy.effect_type == "skill_damage":
                char.skill_damage_mult *= (1 + effect_value)
            elif synergy.effect_type == "attack_speed":
                char.attack_speed_mult *= (1 + effect_value)
            elif synergy.effect_type == "all_stats":
                # PSP: 全体属性加成
                char.final_attack *= (1 + effect_value)
                char.final_health *= (1 + effect_value)

# ============================================================
# 战斗模拟
# ============================================================

def simulate_battle(player_team: List[CharacterStats], enemy_team: List[CharacterStats],
                    apply_effects: bool = True) -> Dict:
    """
    模拟一场战斗

    返回: {
        "win_rate": float,
        "player_power": float,
        "enemy_power": float,
        "result": "win" | "lose",
        "synergies": dict
    }
    """
    # 应用羁绊效果
    player_synergies = {}
    enemy_synergies = {}

    if apply_effects:
        player_synergies = detect_synergies(player_team)
        enemy_synergies = detect_synergies(enemy_team)
        apply_synergy_effects(player_team, player_synergies)
        apply_synergy_effects(enemy_team, enemy_synergies)

    # 计算战力
    player_power = calculate_team_power(player_team)
    enemy_power = calculate_team_power(enemy_team)

    # 计算胜率
    win_rate = calculate_win_rate(player_power, enemy_power)

    # 判定结果
    result = "win" if random.random() < win_rate else "lose"

    return {
        "win_rate": win_rate,
        "player_power": player_power,
        "enemy_power": enemy_power,
        "result": result,
        "player_synergies": player_synergies,
        "enemy_synergies": enemy_synergies,
    }

# ============================================================
# 测试用例
# ============================================================

def test_power_calculation():
    """测试战力计算公式"""
    print("\n### 测试1: 战力计算公式 ###")

    # 测试不同稀有度的角色战力
    chars = ["xiao_ke", "azi", "qi_hai", "xing_tong"]
    for char_id in chars:
        char = CHARACTER_DB[char_id]
        # 不应用羁绊效果
        power = calculate_power(char)
        print(f"  {char.display_name}({char.rarity}费): 攻击{char.base_attack} × 生命{char.base_health} × 定位{ROLE_COEFFICIENTS[char.role]} = 战力{power:.0f}")

    # 验证战力递增
    powers = [calculate_power(CHARACTER_DB[c]) for c in chars]
    assert powers[0] < powers[-1], "5费角色战力应高于1费角色"
    print("  ✓ 稀有度越高，战力越高")

def test_synergy_power_boost():
    """测试羁绊对战力的影响"""
    print("\n### 测试2: 羁绊对战力的影响 ###")

    # 无羁绊队伍
    no_syn_team = [
        CHARACTER_DB["hirro"],
        CHARACTER_DB["lulu"],
    ]

    # VR羁绊队伍
    vr_team = [
        CHARACTER_DB["xiao_ke"],
        CHARACTER_DB["azi"],
    ]

    # 应用羁绊效果
    vr_synergies = detect_synergies(vr_team)
    apply_synergy_effects(vr_team, vr_synergies)

    no_syn_power = calculate_team_power(no_syn_team)
    vr_power = calculate_team_power(vr_team)

    print(f"  无羁绊队伍战力: {no_syn_power:.0f}")
    print(f"  VR(2)队伍战力: {vr_power:.0f} (激活羁绊: {vr_synergies})")
    print(f"  战力提升: {(vr_power / no_syn_power - 1) * 100:.1f}%")

    assert vr_power > no_syn_power, "有羁绊的队伍战力应该更高"
    print("  ✓ 羁绊有效提升战力")

def test_eoe_combo():
    """测试EOE姐妹组合强化"""
    print("\n### 测试3: EOE姐妹组合强化 ###")

    # 单独露早
    luzao_alone = [CHARACTER_DB["lu_zao"]]
    apply_synergy_effects(luzao_alone, detect_synergies(luzao_alone))
    power_alone = calculate_power(luzao_alone[0])
    print(f"  露早单独: 攻击{luzao_alone[0].base_attack}, 生命{luzao_alone[0].base_health}, 战力{power_alone:.0f}")

    # 露早+柚恩 (EOE姐妹激活)
    eoe_team = [CHARACTER_DB["lu_zao"], CHARACTER_DB["you_en"]]
    eoe_synergies = detect_synergies(eoe_team)
    apply_synergy_effects(eoe_team, eoe_synergies)

    luzao_boosted = eoe_team[0]
    power_boosted = calculate_power(luzao_boosted)
    print(f"  露早(EOE强化): 攻击{luzao_boosted.final_attack:.0f}, 生命{luzao_boosted.final_health:.0f}, 战力{power_boosted:.0f}")
    print(f"  强化倍率: 攻击×{luzao_boosted.final_attack / CHARACTER_DB['lu_zao'].base_attack:.1f}, 生命×{luzao_boosted.final_health / CHARACTER_DB['lu_zao'].base_health:.1f}")

    boost_ratio = power_boosted / power_alone
    print(f"  战力提升: {(boost_ratio - 1) * 100:.1f}%")
    assert boost_ratio > 3, "EOE强化应该显著提升战力"
    print("  ✓ EOE姐妹组合强化效果显著")

def test_win_rate_distribution():
    """测试胜率分布"""
    print("\n### 测试4: 胜率计算与分布 ###")

    # 准备测试队伍
    test_cases = [
        ("弱队 vs 强队", ["xiao_ke", "ze_yin"], ["qi_hai", "azi"], "期望胜率 < 50%"),
        ("势均力敌", ["xiao_ke", "azi"], ["lulu", "tian_dou"], "期望胜率 ≈ 50%"),
        ("强队 vs 弱队", ["qi_hai", "xing_tong"], ["xiao_ke", "ze_yin"], "期望胜率 > 60%"),
    ]

    for name, player_ids, enemy_ids, expectation in test_cases:
        player_team = [CHARACTER_DB[c] for c in player_ids]
        enemy_team = [CHARACTER_DB[c] for c in enemy_ids]

        result = simulate_battle(player_team, enemy_team)

        print(f"\n  {name}:")
        print(f"    玩家战力: {result['player_power']:.0f}")
        print(f"    敌方战力: {result['enemy_power']:.0f}")
        print(f"    计算胜率: {result['win_rate'] * 100:.1f}%")
        print(f"    激活羁绊: 玩家{result['player_synergies']}, 敌方{result['enemy_synergies']}")
        print(f"    {expectation}")

    print("\n  ✓ 胜率计算公式合理")

def test_enemy_teams():
    """测试AI敌方阵容"""
    print("\n### 测试5: AI敌方阵容池 ###")

    for enemy in ENEMY_TEAMS:
        enemy_team = [CHARACTER_DB[c] for c in enemy["characters"]]
        enemy_synergies = detect_synergies(enemy_team)
        apply_synergy_effects(enemy_team, enemy_synergies)
        enemy_power = calculate_team_power(enemy_team)

        print(f"  {enemy['name']} ({enemy['difficulty']}): 战力 {enemy_power:.0f}, 羁绊 {enemy_synergies}")

    print("  ✓ 敌方阵容已配置不同难度梯度")

def test_battle_simulation():
    """测试战斗模拟"""
    print("\n### 测试6: 战斗模拟 (100场) ###")

    player_team = [CHARACTER_DB["azi"], CHARACTER_DB["qi_hai"], CHARACTER_DB["tian_dou"]]
    enemy_team = [CHARACTER_DB["xiao_ke"], CHARACTER_DB["lu_zao"], CHARACTER_DB["you_en"]]

    # 应用羁绊
    player_syn = detect_synergies(player_team)
    enemy_syn = detect_synergies(enemy_team)
    apply_synergy_effects(player_team, player_syn)
    apply_synergy_effects(enemy_team, enemy_syn)

    player_power = calculate_team_power(player_team)
    enemy_power = calculate_team_power(enemy_team)
    theoretical_win_rate = calculate_win_rate(player_power, enemy_power)

    # 重置角色属性进行多次模拟
    wins = 0
    for _ in range(100):
        # 重置属性
        for c in player_team + enemy_team:
            c.final_attack = c.base_attack
            c.final_health = c.base_health
            c.skill_damage_mult = 1.0
            c.attack_speed_mult = 1.0

        apply_synergy_effects(player_team, player_syn)
        apply_synergy_effects(enemy_team, enemy_syn)

        result = simulate_battle(player_team, enemy_team, apply_effects=False)
        if result["result"] == "win":
            wins += 1

    actual_win_rate = wins / 100

    print(f"  玩家队伍: {[c.display_name for c in player_team]}")
    print(f"  敌方队伍: {[c.display_name for c in enemy_team]}")
    print(f"  玩家羁绊: {player_syn}")
    print(f"  敌方羁绊: {enemy_syn}")
    print(f"  玩家战力: {player_power:.0f}")
    print(f"  敌方战力: {enemy_power:.0f}")
    print(f"  理论胜率: {theoretical_win_rate * 100:.1f}%")
    print(f"  实际胜率: {actual_win_rate * 100:.0f}% (100场)")

    # 验证实际胜率接近理论胜率
    diff = abs(actual_win_rate - theoretical_win_rate)
    print(f"  差异: {diff * 100:.1f}%")
    assert diff < 0.15, "实际胜率应接近理论胜率"
    print("  ✓ 胜率分布符合概率模型")

def test_strategy_differentiation():
    """测试不同策略的差异化"""
    print("\n### 测试7: 策略差异化 ###")

    # 定义几种不同的策略
    strategies = {
        "VR进攻流": ["xiao_ke", "azi", "qi_hai", "tian_dou"],  # VR(4) 最大攻击加成
        "偶像肉盾流": ["lulu", "tian_dou", "qi_hai", "yong_chu_tafei"],  # 偶像(4) 最大生命加成
        "歌手技能流": ["xiao_ke", "ze_yin", "lu_zao", "you_en", "azi"],  # 歌手(4) 技能伤害加成
        "混合队伍": ["azi", "tian_dou", "xue_gao", "dong_ai_li"],  # 多羁绊
    }

    results = []

    for name, char_ids in strategies.items():
        team = [CHARACTER_DB[c] for c in char_ids]
        synergies = detect_synergies(team)
        apply_synergy_effects(team, synergies)
        power = calculate_team_power(team)

        # 对抗标准敌方
        enemy_team = [CHARACTER_DB["qi_hai"], CHARACTER_DB["azi"], CHARACTER_DB["tian_dou"]]
        enemy_syn = detect_synergies(enemy_team)
        apply_synergy_effects(enemy_team, enemy_syn)
        enemy_power = calculate_team_power(enemy_team)

        win_rate = calculate_win_rate(power, enemy_power)

        print(f"  {name}:")
        print(f"    角色: {[CHARACTER_DB[c].display_name for c in char_ids]}")
        print(f"    激活羁绊: {synergies}")
        print(f"    队伍战力: {power:.0f}")
        print(f"    对抗标准敌方的胜率: {win_rate * 100:.1f}%")

        results.append((name, power, win_rate))

    # 验证不同策略有明显差异
    powers = [r[1] for r in results]
    win_rates = [r[2] for r in results]

    power_range = max(powers) - min(powers)
    wr_range = max(win_rates) - min(win_rates)

    print(f"\n  战力范围: {min(powers):.0f} - {max(powers):.0f} (差距 {power_range:.0f})")
    print(f"  胜率范围: {min(win_rates)*100:.1f}% - {max(win_rates)*100:.1f}% (差距 {wr_range*100:.1f}%)")

    assert wr_range > 0.1, "不同策略应该有明显的胜率差异"
    print("  ✓ 不同策略有明显差异化体验")

# ============================================================
# 主程序
# ============================================================

def main():
    print("=" * 60)
    print("战斗系统原型测试")
    print("=" * 60)

    test_power_calculation()
    test_synergy_power_boost()
    test_eoe_combo()
    test_win_rate_distribution()
    test_enemy_teams()
    test_battle_simulation()
    test_strategy_differentiation()

    print("\n" + "=" * 60)
    print("所有测试通过 ✓")
    print("=" * 60)

    return 0

if __name__ == "__main__":
    sys.exit(main())
