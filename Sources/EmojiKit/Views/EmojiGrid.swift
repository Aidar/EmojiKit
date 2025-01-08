//
//  EmojiGrid.swift
//  EmojiKit
//
//  Created by Daniel Saidi on 2023-11-02.
//  Copyright © 2023-2024 Daniel Saidi. All rights reserved.
//

import SwiftUI

/// This grid can be used to list emojis or emoji categories
/// in a vertical or horizontal grid.
///
/// The grid supports keyboard navigation, and can customize
/// the view for both section titles and grid items. You can
/// trigger a custom `action` when the user selects an emoji.
///
/// You can use an ``EmojiScrollGrid`` to wrap the grid in a
/// `ScrollView` that automatically scrolls to the selection.
///
/// See the <doc:Views-Article> article for full information
/// on how to use these grids.
public struct EmojiGrid<SectionTitle: View, GridItem: View>: View {
    
    /// Create an emoji grid.
    ///
    /// If you provide a list of `emojis`, that list will be
    /// listed in the grid instead of the `categories`.
    ///
    /// - Parameters:
    ///   - axis: The grid axis, by default `.vertical`.
    ///   - emojis: A custom emoji collection to list, if any.
    ///   - categories: The categories to list, by default ``EmojiCategory/recent`` and ``EmojiCategory/standard``.
    ///   - query: The search query to apply, if any.
    ///   - selection: The current grid selection, if any.
    ///   - geometryProxy: An optional geometry proxy, required to perform arrow/move-based navigation.
    ///   - action: An action to trigger when an emoji is tapped or picked, if any.
    ///   - categoryEmojis: An optional function that can customize emojis for a certain category, if any.
    ///   - sectionTitle: A grid section title view builder.
    ///   - gridItem: A grid item view builder.
    public init(
        axis: Axis.Set = .vertical,
        emojis: [Emoji]? = nil,
        categories: [EmojiCategory]? = nil,
        query: String? = nil,
        selection: Binding<Emoji.GridSelection>? = nil,
        geometryProxy: GeometryProxy? = nil,
        action: ((Emoji) -> Void)? = nil,
        categoryEmojis: ((EmojiCategory) -> [Emoji])? = nil,
        @ViewBuilder sectionTitle: @escaping (Emoji.GridSectionTitleParameters) -> SectionTitle,
        @ViewBuilder gridItem: @escaping (Emoji.GridItemParameters) -> GridItem
    ) {
        let emojis = emojis ?? []
        let emojiCategory = EmojiCategory.custom(id: "", name: "", emojis: emojis, iconName: "")
        let defaultCategories: [EmojiCategory] = [.recent] + .standard
        let categories = emojis.isEmpty ? defaultCategories : [emojiCategory]
        let query = query ?? ""
        let searchCategories: [EmojiCategory]? = query.isEmpty ? nil : [.search(query: query)]
        let cats = searchCategories ?? categories
        let filteredCategories = cats.filter { !$0.emojis.isEmpty }

        self.axis = axis
        self.categories = filteredCategories
        self.query = query
        self.geometryProxy = geometryProxy
        self.action = action ?? { _ in }
        self.categoryEmojis = categoryEmojis ?? { $0.emojis }
        self.section = sectionTitle
        self.item = gridItem
        self._selection = selection ?? .constant(.init())
    }
    
    private let axis: Axis.Set
    private let categories: [EmojiCategory]
    private let query: String
    private let geometryProxy: GeometryProxy?
    private let action: (Emoji) -> Void
    private let categoryEmojis: (EmojiCategory) -> [Emoji]
    private let section: (Emoji.GridSectionTitleParameters) -> SectionTitle
    private let item: (Emoji.GridItemParameters) -> GridItem

    @Binding var selection: Emoji.GridSelection

    @Environment(\.emojiGridStyle) var style
    @Environment(\.layoutDirection) var layoutDirection

    @State var popoverSelection: Emoji.GridSelection?

    public var body: some View {
        bodyContent.id(query)
    }

    @ViewBuilder
    private var bodyContent: some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            grid
                .focusable(true)
                .focusEffectDisabled(!style.prefersFocusEffect)
                #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
                .onKeyPress {
                    var result: Bool
                    switch $0.key {
                    case .downArrow: result = handleDirection(.down)
                    case .leftArrow: result = handleDirection(.left)
                    case .escape: result = handleEscape()
                    case .return: result = handleReturn($0)
                    case .rightArrow: result = handleDirection(.right)
                    case .upArrow: result = handleDirection(.up)
                    default: result = false
                    }
                    return result ? .handled : .ignored
                }
                #endif
                #if os(tvOS)
                .onMoveCommand(perform: selectEmoji)
                #endif
                .padding(style.padding)
        } else {
            grid
                .padding(style.padding)
        }
    }
}

private extension EmojiGrid {

    func handleDirection(_ direction: Emoji.GridDirection) -> Bool {
        selectEmoji(with: direction)
        return true
    }

    func handleEscape() -> Bool {
        selection.reset()
        return true
    }

    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
    func handleReturn(_ press: SwiftUI.KeyPress) -> Bool {
        if press.modifiers.isEmpty { return pickSelectedEmoji() }
        if press.modifiers == .option { return showPopoverForSelection() }
        return false
    }
    #endif

    func pickEmoji(_ emoji: Emoji) {
        action(emoji)
        emoji.registerUserSelection()
    }

    func pickSelectedEmoji() -> Bool {
        guard let emoji = selection.emoji else { return false }
        pickEmoji(emoji)
        return true
    }

    func selectEmoji(
        _ emoji: Emoji,
        in category: EmojiCategory,
        pick: Bool = false,
        skintonePopover: Bool = false
    ) {
        selection = .init(emoji: emoji, category: category)
        if pick { _ = pickSelectedEmoji() }
        if skintonePopover { popoverSelection = selection }
    }

    #if os(macOS) || os(tvOS)
    func selectEmoji(
        with direction: MoveCommandDirection
    ) {
        selectEmoji(with: direction.emojiGridDirection)
    }
    #endif

    func selectEmoji(
        with direction: Emoji.GridDirection
    ) {
        guard let geo = geometryProxy else { return }
        let layoutDirection = direction.transform(for: layoutDirection)
        let navDirection = layoutDirection.navigationDirection(for: axis)
        if selection.isEmpty { return selectFirstCategory() }
        guard
            let category = selection.category,
            let emoji = selection.emoji
        else { return }

        let emojis = emojis(for: category)
        guard
            let index = emojis.firstIndex(of: emoji)
        else { return }

        let itemsPerRow = geo.itemsPerRow(
            for: axis,
            style: style
        )

        let newIndex = layoutDirection.destinationIndex(
            for: axis,
            currentIndex: index,
            itemsPerRow: itemsPerRow
        )

        if let emoji = emojis.emoji(at: newIndex) {
            selectEmoji(emoji, in: category)
        } else if navDirection == .back {
            guard
                let cat = categories.category(before: category),
                let emoji = self.emojis(for: cat).last
            else { return }
            selectEmoji(emoji, in: cat)
        } else {
            guard
                let cat = categories.category(after: category),
                let emoji = self.emojis(for: cat).first
            else { return }
            selectEmoji(emoji, in: cat)
        }
    }

    func selectFirstCategory() {
        let firstNonEmpty = categories.first { !emojis(for: $0).isEmpty }
        guard let category = firstNonEmpty else { return }
        let emoji = emojis(for: category).first
        selection.select(emoji: emoji, in: category)
    }

    func showPopoverForSelection() -> Bool {
        popoverSelection = selection
        return true
    }
}

private extension EmojiGrid {

    @ViewBuilder
    var grid: some View {
        if axis == .horizontal {
            LazyHGrid(
                rows: style.items,
                alignment: .top,
                spacing: style.itemSpacing,
                content: gridContent
            )
        } else {
            LazyVGrid(
                columns: style.items,
                alignment: .leading,
                spacing: style.itemSpacing,
                content: gridContent
            )
        }
    }
    
    func gridContent() -> some View {
        ForEach(Array(categories.enumerated()), id: \.offset) {
            let offset = $0.offset
            let category = $0.element
            if hasEmojis(for: category) {
                Section {
                    gridContent(for: category, at: offset)
                } header: {
                    gridTitle(for: category, at: offset)
                        .padding(.top, offset > 0 ? style.sectionSpacing : 0)
                }
            }
        }
    }
    
    @ViewBuilder
    func gridContent(
        for category: EmojiCategory,
        at index: Int
    ) -> some View {
        let emojis = emojis(for: category)
        ForEach(Array(emojis.enumerated()), id: \.offset) {
            gridContent(
                for: category,
                at: index,
                emoji: $0.element,
                emojiIndex: $0.offset
            )
        }
    }

    @ViewBuilder
    func gridContent(
        for category: EmojiCategory,
        at categoryIndex: Int,
        emoji: Emoji,
        emojiIndex: Int
    ) -> some View {
        let params = Emoji.GridItemParameters(
            emoji: emoji,
            emojiIndex: emojiIndex,
            category: category,
            categoryIndex: categoryIndex,
            isSelected: isSelected(emoji, in: category),
            view: Emoji.GridItem(
                emoji,
                isSelected: isSelected(emoji, in: category)
            )
        )
        EmojiGridItemWrapper(
            params: params,
            action: { emoji, _ in pickEmoji(emoji) },
            popoverSelection: $popoverSelection, 
            content: { item(params) }
        )
        .font(style.font)
        .onTapGesture {
            if popoverSelection != nil { return }
            selectEmoji(emoji, in: category, pick: true)
        }
        // .prefersDraggable(emoji)     TODO: Fix Conflicts with popover
        .onLongPressGesture {
            selectEmoji(emoji, in: category, skintonePopover: true)
        }
        .id(emoji.id(in: category))
    }

    @ViewBuilder
    func gridTitle(
        for category: EmojiCategory,
        at index: Int
    ) -> some View {
        if axis == .vertical, categories.count > 1 {
            section(
                .init(
                    category: category,
                    index: index,
                    view: Emoji.GridSectionTitle(category)
                )
            )
            .id(category.id)
        }
    }
}

private extension View {
    
    @ViewBuilder
    func prefersDraggable(
        _ emoji: Emoji
    ) -> some View {
        #if os(watchOS) || os(tvOS)
        self
        #else
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            self.draggable(emoji)
        } else {
            self
        }
        #endif
    }
}

private extension EmojiGrid {
    
    func emojis(
        for category: EmojiCategory
    ) -> [Emoji] {
        categoryEmojis(category)
    }
    
    func hasEmojis(
        for category: EmojiCategory
    ) -> Bool {
        !emojis(for: category).isEmpty
    }
    
    func isSelected(
        _ emoji: Emoji,
        in category: EmojiCategory
    ) -> Bool {
        if categories.count == 1 { return selection.matches(emoji: emoji) }
        return selection.matches(emoji: emoji, category: category)
    }
}

#Preview {
    
    struct Preview: View {
        
        @State var query: String = ""
        
        @State var selection = Emoji.GridSelection(
            emoji: .init("😀"),
            category: .smileysAndPeople
        )
        
        var body: some View {
            VStack {
                TextField("Search", text: $query)
                    .padding(.horizontal, 3)
                
                Divider()
                
                ScrollViewReader { proxy in
                    EmojiScrollGrid(
                        axis: .vertical,
                        categories: [.recent] + .standard,
                        query: query,
                        selection: $selection,
                        categoryEmojis: { $0.emojis /*Array($0.emojis.prefix(4))*/ },
                        sectionTitle: { $0.view },
                        gridItem: { $0.view }
                    )
                    .emojiGridStyle(.small)
                    .onAppear {
                        proxy.scrollTo(selection)
                    }
                    .onChange(of: selection) { selection in
                        proxy.scrollTo(selection)
                    }
                }
            }
        }
    }
    
    return Preview()
}
