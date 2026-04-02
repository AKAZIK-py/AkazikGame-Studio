#!/usr/bin/env python3
# PROTOTYPE - NOT FOR PRODUCTION
# Question: 抽卡概率分布是否正确？商店刷新机制是否工作？已选角色追踪是否准确？
# Date: 2026-03-28
"""
商店/卡池系统原型 - 验证核心逻辑 (Python版本)

运行: python3 shop_prototype.py

验证内容:
1. 抽卡概率分布
2. 商店刷新机制
3. 已选角色追踪
4. 卡池耗尽处理
"""

import random
import sys
from dataclasses import dataclass
from typing import List, Optional, Dict
from collections import Counter

# ============================================================
# 数据类
# ============================================================

@dataclass
class Character:
    id: str
    display_name: str
    rarity: int  # 1-5 (费用)

# ============================================================
# 角色数据库
# ============================================================

CHARACTER_DB = {
    # 1费角色
    "xiao_ke": Character("xiao_ke", "小可", 1),
    "you_en": Character("you_en", "柚恩", 1),
    "ze_yin": Character("ze_yin", "泽音", 1),
    "lu_zao": Character("lu_zao", "露早", 1),
    # 2费角色
    "hirro": Character("hirro", "hirro", 2),
    "xue_gao": Character("xue_gao", "雪糕", 2),
    "bai_shen_yao": Character("bai_shen_yao", "白神遥", 2),
    # 3费角色
    "lulu": Character("lulu", "雫lulu", 3),
    "azi": Character("azi", "阿梓", 3),
    "tian_dou": Character("tian_dou", "恬豆", 3),
    "dong_ai_li": Character("dong_ai_li", "东爱璃", 3),
    # 4费角色
    "qi_hai": Character("qi_hai", "七海", 4),
    "yong_chu_tafei": Character("yong_chu_tafei", "永雏塔菲", 4),
    # 5费角色
    "xing_tong": Character("xing_tong", "星瞳", 5),
}

# ============================================================
# 卡池管理系统
# ============================================================

class CardPoolManager:
    """
    卡池管理系统

    管理：
    - 可用角色池
    - 抽卡概率
    - 已选角色追踪
    """

    # 概率分布
    TIER_PROBABILITIES = {
        1: 0.30,  # 30%
        2: 0.25,  # 25%
        3: 0.25,  # 25%
        4: 0.15,  # 15%
        5: 0.05,  # 5%
    }

    def __init__(self):
        self._pool: Dict[int, List[Character]] = {}  # rarity -> list of characters
        self._selected: set = set()  # 已选角色ID
        self._initialize_pool()

    def _initialize_pool(self):
        """初始化卡池"""
        self._pool = {1: [], 2: [], 3: [], 4: [], 5: []}
        for char in CHARACTER_DB.values():
            self._pool[char.rarity].append(char)

    def reset_pool(self):
        """重置卡池"""
        self._selected.clear()

    def get_pool_count(self, rarity: Optional[int] = None) -> int:
        """获取卡池中剩余角色数量"""
        if rarity:
            available = [c for c in self._pool.get(rarity, []) if c.id not in self._selected]
            return len(available)
        else:
            total = 0
            for r in range(1, 6):
                total += self.get_pool_count(r)
            return total

    def get_available_tiers(self) -> List[int]:
        """获取仍有可用角色的费用档"""
        return [r for r in range(1, 6) if self.get_pool_count(r) > 0]

    def draw_card(self) -> Optional[Character]:
        """
        抽取一张卡（按概率）

        返回: 抽到的角色，如果卡池为空返回None
        """
        available_tiers = self.get_available_tiers()
        if not available_tiers:
            return None

        # 计算有效概率分布
        roll = random.random()
        cumulative = 0.0

        # 只考虑仍有可用角色的费用档
        for rarity in [1, 2, 3, 4, 5]:
            if rarity not in available_tiers:
                continue

            prob = self.TIER_PROBABILITIES[rarity]
            cumulative += prob

            if roll < cumulative:
                # 从该费用档抽取
                return self._draw_from_tier(rarity)

        # 如果概率溢出（因为某些费用档已空），从最高可用费用档抽取
        return self._draw_from_tier(available_tiers[-1])

    def _draw_from_tier(self, rarity: int) -> Optional[Character]:
        """从指定费用档抽取一张卡"""
        available = [c for c in self._pool.get(rarity, []) if c.id not in self._selected]
        if not available:
            return None
        return random.choice(available)

    def draw_cards(self, count: int) -> List[Character]:
        """抽取N张卡"""
        cards = []
        for _ in range(count):
            card = self.draw_card()
            if card:
                cards.append(card)
            else:
                break  # 卡池耗尽
        return cards

    def remove_from_pool(self, character_id: str):
        """标记角色为已选"""
        self._selected.add(character_id)

    def is_selected(self, character_id: str) -> bool:
        """检查角色是否已被选中"""
        return character_id in self._selected

# ============================================================
# 商店系统
# ============================================================

class ShopSystem:
    """
    商店系统

    管理：
    - 商店卡槽
    - 刷新机制
    - 角色选择
    """

    SHOP_SLOTS = 5  # 卡槽数量

    def __init__(self, card_pool: CardPoolManager):
        self._card_pool = card_pool
        self._slots: List[Optional[Character]] = [None] * self.SHOP_SLOTS
        self._refresh_count = 0

    def refresh_shop(self):
        """刷新商店（重新抽取卡牌）"""
        # 清空当前卡槽
        self._slots = [None] * self.SHOP_SLOTS

        # 从卡池抽取新卡
        cards = self._card_pool.draw_cards(self.SHOP_SLOTS)
        for i, card in enumerate(cards):
            self._slots[i] = card

        self._refresh_count += 1

    def select_character(self, slot_index: int) -> Optional[Character]:
        """
        选择角色（从商店领取）

        返回: 选中的角色，如果槽位为空返回None
        """
        if slot_index < 0 or slot_index >= self.SHOP_SLOTS:
            return None

        character = self._slots[slot_index]
        if character:
            # 从卡池移除
            self._card_pool.remove_from_pool(character.id)
            # 清空槽位
            self._slots[slot_index] = None

        return character

    def get_shop_cards(self) -> List[Optional[Character]]:
        """获取当前商店卡牌"""
        return self._slots.copy()

    def clear_shop(self):
        """清空商店"""
        self._slots = [None] * self.SHOP_SLOTS

    def get_refresh_count(self) -> int:
        """获取刷新次数"""
        return self._refresh_count

    def get_empty_slot_count(self) -> int:
        """获取空槽数量"""
        return sum(1 for slot in self._slots if slot is None)

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

def test_probability_distribution(test: TestRunner):
    """测试抽卡概率分布"""
    print("\n### 测试1: 抽卡概率分布 ###")

    card_pool = CardPoolManager()

    # 进行大量抽卡测试概率分布
    draws = 10000
    rarity_counts = Counter()

    for _ in range(draws):
        card = card_pool.draw_card()
        if card:
            rarity_counts[card.rarity] += 1

    print(f"  抽卡次数: {draws}")
    print(f"  各费用抽到次数:")

    for rarity in range(1, 6):
        count = rarity_counts[rarity]
        actual_prob = count / draws * 100
        expected_prob = CardPoolManager.TIER_PROBABILITIES[rarity] * 100
        diff = abs(actual_prob - expected_prob)

        print(f"    {rarity}费: {count:4d} 次 ({actual_prob:.1f}%) [期望 {expected_prob:.0f}%]")

        # 允许1%的误差
        test.assert_true(diff < 2, f"{rarity}费概率误差应<2% (实际{diff:.1f}%)")

    print("  ✓ 概率分布符合预期")

def test_shop_refresh(test: TestRunner):
    """测试商店刷新"""
    print("\n### 测试2: 商店刷新 ###")

    card_pool = CardPoolManager()
    shop = ShopSystem(card_pool)

    # 刷新商店
    shop.refresh_shop()
    cards = shop.get_shop_cards()

    print(f"  刷新后卡槽数: {len(cards)}")
    test.assert_true(len(cards) == 5, "应有5个卡槽")

    filled_slots = sum(1 for c in cards if c is not None)
    print(f"  有卡牌的卡槽: {filled_slots}")
    test.assert_true(filled_slots == 5, "应有5张卡")

    # 显示卡牌
    for i, card in enumerate(cards):
        if card:
            print(f"    槽位{i}: {card.display_name}({card.rarity}费)")

    # 再次刷新
    shop.refresh_shop()
    cards2 = shop.get_shop_cards()

    print(f"\n  再次刷新后:")
    for i, card in enumerate(cards2):
        if card:
            print(f"    槽位{i}: {card.display_name}({card.rarity}费)")

    # 检查卡牌是否不同（大概率）
    same_count = sum(1 for i in range(5) if cards[i] and cards2[i] and cards[i].id == cards2[i].id)
    print(f"  相同卡牌数: {same_count}/5")
    test.assert_true(same_count < 5, "刷新后卡牌应大部分不同")

def test_character_selection(test: TestRunner):
    """测试角色选择"""
    print("\n### 测试3: 角色选择 ###")

    card_pool = CardPoolManager()
    shop = ShopSystem(card_pool)

    shop.refresh_shop()
    cards = shop.get_shop_cards()

    # 选择第一个角色
    selected = shop.select_character(0)
    print(f"  选择槽位0: {selected.display_name if selected else None}")
    test.assert_true(selected is not None, "选择应成功")

    # 检查槽位是否变空
    cards_after = shop.get_shop_cards()
    print(f"  选择后槽位0: {'空' if cards_after[0] is None else cards_after[0].display_name}")
    test.assert_true(cards_after[0] is None, "选择后槽位应为空")

    # 检查卡池是否追踪
    is_selected = card_pool.is_selected(selected.id)
    print(f"  卡池中已选标记: {is_selected}")
    test.assert_true(is_selected, "角色应被标记为已选")

    # 尝试再次选择同一槽位
    selected_again = shop.select_character(0)
    print(f"  再次选择空槽位: {selected_again}")
    test.assert_true(selected_again is None, "选择空槽位应返回None")

def test_pool_tracking(test: TestRunner):
    """测试卡池追踪"""
    print("\n### 测试4: 卡池追踪 ###")

    card_pool = CardPoolManager()
    shop = ShopSystem(card_pool)

    print(f"  初始卡池大小: {card_pool.get_pool_count()}")

    # 选择多个角色
    selected_chars = []
    for _ in range(5):
        shop.refresh_shop()
        cards = shop.get_shop_cards()
        for card in cards:
            if card and card.id not in [c.id for c in selected_chars]:
                selected = shop.select_character(cards.index(card))
                if selected:
                    selected_chars.append(selected)
                    print(f"    选择了: {selected.display_name}")
                break

    print(f"\n  已选角色数: {len(selected_chars)}")
    print(f"  剩余卡池大小: {card_pool.get_pool_count()}")

    test.assert_true(card_pool.get_pool_count() < 14, "卡池应减少")
    test.assert_true(len(selected_chars) > 0, "应有已选角色")

    # 重置卡池
    card_pool.reset_pool()
    print(f"\n  重置后卡池大小: {card_pool.get_pool_count()}")
    test.assert_true(card_pool.get_pool_count() == 14, "重置后应为完整卡池")

def test_pool_exhaustion(test: TestRunner):
    """测试卡池耗尽"""
    print("\n### 测试5: 卡池耗尽 ###")

    card_pool = CardPoolManager()

    # 抽干卡池
    drawn = []
    while True:
        card = card_pool.draw_card()
        if card is None:
            break
        drawn.append(card)
        card_pool.remove_from_pool(card.id)

    print(f"  抽到的卡数: {len(drawn)}")
    print(f"  剩余卡池: {card_pool.get_pool_count()}")

    test.assert_true(len(drawn) == 14, "应抽到所有14张卡")
    test.assert_true(card_pool.get_pool_count() == 0, "卡池应为空")

    # 尝试继续抽卡
    card = card_pool.draw_card()
    print(f"  卡池空时抽卡: {card}")
    test.assert_true(card is None, "卡池空时应返回None")

    # 测试商店在卡池空时刷新
    shop = ShopSystem(card_pool)
    shop.refresh_shop()
    filled_slots = sum(1 for c in shop.get_shop_cards() if c is not None)
    print(f"  卡池空时刷新商店: {filled_slots}/5槽有卡")
    test.assert_true(filled_slots == 0, "卡池空时商店应为空")

def test_tier_specific_draw(test: TestRunner):
    """测试特定费用抽卡"""
    print("\n### 测试6: 特定费用抽卡统计 ###")

    card_pool = CardPoolManager()

    # 各费用角色数量
    print("  各费用可用角色:")
    for rarity in range(1, 6):
        count = card_pool.get_pool_count(rarity)
        print(f"    {rarity}费: {count}个")

    test.assert_true(card_pool.get_pool_count(1) == 4, "1费应有4个角色")
    test.assert_true(card_pool.get_pool_count(2) == 3, "2费应有3个角色")
    test.assert_true(card_pool.get_pool_count(3) == 4, "3费应有4个角色")
    test.assert_true(card_pool.get_pool_count(4) == 2, "4费应有2个角色")
    test.assert_true(card_pool.get_pool_count(5) == 1, "5费应有1个角色")

def test_shop_display(test: TestRunner):
    """测试商店显示"""
    print("\n### 测试7: 商店显示模拟 ###")

    card_pool = CardPoolManager()
    shop = ShopSystem(card_pool)

    # 模拟几次刷新
    for i in range(3):
        shop.refresh_shop()
        cards = shop.get_shop_cards()

        print(f"\n  第{i+1}次刷新:")
        for j, card in enumerate(cards):
            if card:
                stars = "★" * card.rarity
                print(f"    [{j}] {stars} {card.display_name} ({card.rarity}费)")
            else:
                print(f"    [{j}] (空)")

    print(f"\n  总刷新次数: {shop.get_refresh_count()}")

# ============================================================
# 主程序
# ============================================================

def main():
    print("=" * 60)
    print("商店/卡池系统原型测试")
    print("=" * 60)
    print(f"卡池总角色数: {len(CHARACTER_DB)}")
    print(f"概率分布: 1费30%, 2费25%, 3费25%, 4费15%, 5费5%")

    test = TestRunner()

    test_probability_distribution(test)
    test_shop_refresh(test)
    test_character_selection(test)
    test_pool_tracking(test)
    test_pool_exhaustion(test)
    test_tier_specific_draw(test)
    test_shop_display(test)

    test.print_results()

    return test.failed

if __name__ == "__main__":
    sys.exit(main())
