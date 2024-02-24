# Features

This article describes the EmojiKit skin tone support.


KeyboardKit defines skin tone variations for emojis that have such variations:

```swift
Emoji("👍").hasSkinToneVariants     // true
Emoji("🚀").hasSkinToneVariants     // false
Emoji("👍🏿").neutralSkinToneVariant  // 👍
Emoji("👍").skinToneVariants        // 👍👍🏻👍🏼👍🏽👍🏾👍🏿
Emoji("👍").skinToneVariantActions  // The above variants as keyboard actions
```

Skin tones will automatically be used as secondary callout actions when using an ``Emoji/GridPicker``. 

> Note: Skin tone support for emojis with multiple skin tone components are currently not supported, such as two persons kissing.
