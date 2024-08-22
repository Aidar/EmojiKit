# Getting Started

This article describes how to get started with EmojiKit.

@Metadata {
    
    @PageImage(
        purpose: card,
        source: "Page",
        alt: "Page icon"
    )
    
    @PageColor(blue)
}

EmojiKit is easy to use. It's based on basic models, like ``Emoji`` and ``EmojiCategory``, which provides you with all the information you need to create sophisticated emoji-based apps and software.



## Emojis

EmojiKit has an ``Emoji`` struct that lets you work with emojis in a structured way:

```swift
let emoji = Emoji("😀")
let emojis = Emoji.all          // 😀😃😄😁😆🥹😅😂🤣🥲...
```

The ``Emoji`` type has unicode properties, for instance:

```swift
Emoji("👍").unicodeIdentifier   // \\N{THUMBS UP SIGN}
```

You can read more in the <doc:Emoji-Article> article.



## Emoji Categories

EmojiKit has an ``EmojiCategory`` enum that defines all standard emoji categories and their included emojis:

```swift
try EmojiCategory.smileysAndPeople.emojis  // 😀😃😄...
EmojiCategory.standard  // [.frequent, .smileyAndPeople, ...]
```

You can read more in the <doc:EmojiCategory-Article> article.



## Emoji Versions

EmojiKit has an ``EmojiVersion`` type that defines all emoji versions, as well as their platform availability and included emojis:

```swift
let version = Emoji.Version.current
let v15 = Emoji.Version.v15
v15.emojis      // 🫨🫸🫷🪿🫎🪼🫏🪽🪻🫛🫚🪇🪈🪮🪭🩷🩵🩶🪯🛜
```

You can read more in the <doc:EmojiVersion-Article> article.



## Views

EmojiKit has views that let you list and select emojis:

@TabNavigator {
    
    @Tab("EmojiGrid") {
        @Row {
            @Column {
                EmojiKit has an ``EmojiGrid`` that can be used to list and pick emojis in a horizontal or vertical grid.        
            }
            @Column {
                ![EmojiGrid](emojigrid.jpg)       
            }
        }
    }
        
    @Tab("EmojiScrollGrid") {
        @Row {
            @Column {
                EmojiKit has an ``EmojiScrollGrid`` that wraps an ``EmojiGrid`` and automatically scrolls to the current selection.        
            }
            @Column {
                ![EmojiGrid](emojigrid.jpg)       
            }
        }
    }
}

You can read more in the <doc:Views-Article> article.



## Further Reading

@Links(visualStyle: detailedGrid) {
    
    - <doc:Emoji-Article>
    - <doc:EmojiCategory-Article>
    - <doc:EmojiVersion-Article>
    - <doc:Extensions-Article>
    - <doc:Localization-Article>
    - <doc:SkinTones-Article>
}
