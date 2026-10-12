// PhonicsData.swift — Educational phonics & theme data
// Letter/number to word, emoji, and phrase mappings

import Foundation

struct PhonicsEntry {
    let letter: Character
    let word: String
    let emoji: String
    let phrase: String     // e.g. "A is for Apple!"
    let soundDescription: String // For accessibility

    var displayText: String { "\(letter)" }
    var fullDisplay: String { "\(emoji)\n\(word)" }
}

struct NumberEntry {
    let digit: Int
    let word: String
    let emoji: String
    let phrase: String

    var displayText: String { "\(digit)" }
}

struct ThemeEntry {
    let name: String
    let emoji: String
    let sound: String // Description of the sound to play
}

// MARK: - Phonics Data

struct PhonicsData {

    static let letters: [PhonicsEntry] = [
        PhonicsEntry(letter: "A", word: "Apple",      emoji: "🍎", phrase: "A is for Apple!",      soundDescription: "crunchy apple bite"),
        PhonicsEntry(letter: "B", word: "Butterfly",   emoji: "🦋", phrase: "B is for Butterfly!",   soundDescription: "gentle flutter"),
        PhonicsEntry(letter: "C", word: "Cat",         emoji: "🐱", phrase: "C is for Cat!",         soundDescription: "soft meow"),
        PhonicsEntry(letter: "D", word: "Duckling",    emoji: "🐥", phrase: "D is for Duckling!",    soundDescription: "quack quack"),
        PhonicsEntry(letter: "E", word: "Elephant",    emoji: "🐘", phrase: "E is for Elephant!",    soundDescription: "trumpet call"),
        PhonicsEntry(letter: "F", word: "Fox",         emoji: "🦊", phrase: "F is for Fox!",         soundDescription: "playful yip"),
        PhonicsEntry(letter: "G", word: "Giraffe",     emoji: "🦒", phrase: "G is for Giraffe!",     soundDescription: "tall friend"),
        PhonicsEntry(letter: "H", word: "Hedgehog",    emoji: "🦔", phrase: "H is for Hedgehog!",    soundDescription: "tiny snuffle"),
        PhonicsEntry(letter: "I", word: "Iguana",      emoji: "🦎", phrase: "I is for Iguana!",      soundDescription: "cool lizard"),
        PhonicsEntry(letter: "J", word: "Jellyfish",   emoji: "🪼", phrase: "J is for Jellyfish!",   soundDescription: "ocean wobble"),
        PhonicsEntry(letter: "K", word: "Koala",       emoji: "🐨", phrase: "K is for Koala!",       soundDescription: "sleepy snore"),
        PhonicsEntry(letter: "L", word: "Lion",        emoji: "🦁", phrase: "L is for Lion!",        soundDescription: "mighty roar"),
        PhonicsEntry(letter: "M", word: "Monkey",      emoji: "🐵", phrase: "M is for Monkey!",      soundDescription: "cheeky chatter"),
        PhonicsEntry(letter: "N", word: "Newt",        emoji: "🦎", phrase: "N is for Newt!",        soundDescription: "tiny splash"),
        PhonicsEntry(letter: "O", word: "Owl",         emoji: "🦉", phrase: "O is for Owl!",         soundDescription: "wise hoot"),
        PhonicsEntry(letter: "P", word: "Penguin",     emoji: "🐧", phrase: "P is for Penguin!",     soundDescription: "happy waddle"),
        PhonicsEntry(letter: "Q", word: "Quail",       emoji: "🐦", phrase: "Q is for Quail!",       soundDescription: "gentle chirp"),
        PhonicsEntry(letter: "R", word: "Rabbit",      emoji: "🐰", phrase: "R is for Rabbit!",      soundDescription: "hop hop"),
        PhonicsEntry(letter: "S", word: "Starfish",    emoji: "⭐", phrase: "S is for Starfish!",    soundDescription: "sparkle"),
        PhonicsEntry(letter: "T", word: "Turtle",      emoji: "🐢", phrase: "T is for Turtle!",      soundDescription: "slow hello"),
        PhonicsEntry(letter: "U", word: "Unicorn",     emoji: "🦄", phrase: "U is for Unicorn!",     soundDescription: "magical sparkle"),
        PhonicsEntry(letter: "V", word: "Volcano",     emoji: "🌋", phrase: "V is for Volcano!",     soundDescription: "rumble"),
        PhonicsEntry(letter: "W", word: "Whale",       emoji: "🐋", phrase: "W is for Whale!",       soundDescription: "deep song"),
        PhonicsEntry(letter: "X", word: "Xylophone",   emoji: "🎵", phrase: "X is for Xylophone!",   soundDescription: "ding ding"),
        PhonicsEntry(letter: "Y", word: "Yak",         emoji: "🐃", phrase: "Y is for Yak!",         soundDescription: "deep moo"),
        PhonicsEntry(letter: "Z", word: "Zebra",       emoji: "🦓", phrase: "Z is for Zebra!",       soundDescription: "galloping"),
    ]

    static let numbers: [NumberEntry] = [
        NumberEntry(digit: 0, word: "Zero",  emoji: "0️⃣", phrase: "Zero"),
        NumberEntry(digit: 1, word: "One",   emoji: "1️⃣", phrase: "One"),
        NumberEntry(digit: 2, word: "Two",   emoji: "2️⃣", phrase: "Two"),
        NumberEntry(digit: 3, word: "Three", emoji: "3️⃣", phrase: "Three"),
        NumberEntry(digit: 4, word: "Four",  emoji: "4️⃣", phrase: "Four"),
        NumberEntry(digit: 5, word: "Five",  emoji: "5️⃣", phrase: "Five"),
        NumberEntry(digit: 6, word: "Six",   emoji: "6️⃣", phrase: "Six"),
        NumberEntry(digit: 7, word: "Seven", emoji: "7️⃣", phrase: "Seven"),
        NumberEntry(digit: 8, word: "Eight", emoji: "8️⃣", phrase: "Eight"),
        NumberEntry(digit: 9, word: "Nine",  emoji: "9️⃣", phrase: "Nine"),
    ]

    // MARK: - Theme Entries (Random Mode)

    static let animalTheme: [ThemeEntry] = [
        ThemeEntry(name: "Puppy",     emoji: "🐶", sound: "Woof woof!"),
        ThemeEntry(name: "Kitty",     emoji: "🐱", sound: "Meow!"),
        ThemeEntry(name: "Bunny",     emoji: "🐰", sound: "Hop hop!"),
        ThemeEntry(name: "Bear",      emoji: "🐻", sound: "Grr!"),
        ThemeEntry(name: "Panda",     emoji: "🐼", sound: "Munch munch!"),
        ThemeEntry(name: "Frog",      emoji: "🐸", sound: "Ribbit!"),
        ThemeEntry(name: "Chick",     emoji: "🐤", sound: "Cheep cheep!"),
        ThemeEntry(name: "Dolphin",   emoji: "🐬", sound: "Click click!"),
        ThemeEntry(name: "Butterfly", emoji: "🦋", sound: "Flutter!"),
        ThemeEntry(name: "Ladybug",   emoji: "🐞", sound: "Buzz!"),
        ThemeEntry(name: "Octopus",   emoji: "🐙", sound: "Squish!"),
        ThemeEntry(name: "Parrot",    emoji: "🦜", sound: "Hello!"),
        ThemeEntry(name: "Hamster",   emoji: "🐹", sound: "Squeak!"),
        ThemeEntry(name: "Bee",       emoji: "🐝", sound: "Buzzz!"),
        ThemeEntry(name: "Snail",     emoji: "🐌", sound: "Slow and steady!"),
    ]

    static let vehicleTheme: [ThemeEntry] = [
        ThemeEntry(name: "Car",        emoji: "🚗", sound: "Vroom vroom!"),
        ThemeEntry(name: "Bus",        emoji: "🚌", sound: "Beep beep!"),
        ThemeEntry(name: "Train",      emoji: "🚂", sound: "Choo choo!"),
        ThemeEntry(name: "Airplane",   emoji: "✈️",  sound: "Whoosh!"),
        ThemeEntry(name: "Rocket",     emoji: "🚀", sound: "Blast off!"),
        ThemeEntry(name: "Boat",       emoji: "⛵", sound: "Splash!"),
        ThemeEntry(name: "Helicopter", emoji: "🚁", sound: "Choppa choppa!"),
        ThemeEntry(name: "Fire Truck", emoji: "🚒", sound: "Wee-woo!"),
        ThemeEntry(name: "Bicycle",    emoji: "🚲", sound: "Ring ring!"),
        ThemeEntry(name: "Tractor",    emoji: "🚜", sound: "Putt putt!"),
    ]

    static let musicalTheme: [ThemeEntry] = [
        ThemeEntry(name: "Guitar",     emoji: "🎸", sound: "Strum!"),
        ThemeEntry(name: "Drum",       emoji: "🥁", sound: "Boom boom!"),
        ThemeEntry(name: "Piano",      emoji: "🎹", sound: "Ding!"),
        ThemeEntry(name: "Violin",     emoji: "🎻", sound: "Swee!"),
        ThemeEntry(name: "Trumpet",    emoji: "🎺", sound: "Toot toot!"),
        ThemeEntry(name: "Tambourine", emoji: "🪇", sound: "Jingle!"),
        ThemeEntry(name: "Maracas",    emoji: "🪇", sound: "Shake shake!"),
        ThemeEntry(name: "Flute",      emoji: "🪈", sound: "Tweeee!"),
    ]

    static let babyTheme: [ThemeEntry] = [
        ThemeEntry(name: "Baby",       emoji: "👶", sound: "Goo goo!"),
        ThemeEntry(name: "Bottle",     emoji: "🍼", sound: "Glug glug!"),
        ThemeEntry(name: "Teddy",      emoji: "🧸", sound: "Cuddle!"),
        ThemeEntry(name: "Star",       emoji: "⭐", sound: "Twinkle!"),
        ThemeEntry(name: "Moon",       emoji: "🌙", sound: "Goodnight!"),
        ThemeEntry(name: "Rainbow",    emoji: "🌈", sound: "Wow!"),
        ThemeEntry(name: "Heart",      emoji: "❤️",  sound: "Love!"),
        ThemeEntry(name: "Sun",        emoji: "☀️",  sound: "Shiny!"),
        ThemeEntry(name: "Cloud",      emoji: "☁️",  sound: "Fluffy!"),
        ThemeEntry(name: "Balloon",    emoji: "🎈", sound: "Pop!"),
    ]

    static let highContrastTheme: [ThemeEntry] = [
        ThemeEntry(name: "Circle",     emoji: "🔴", sound: "Red circle!"),
        ThemeEntry(name: "Square",     emoji: "🟦", sound: "Blue square!"),
        ThemeEntry(name: "Triangle",   emoji: "🔺", sound: "Red triangle!"),
        ThemeEntry(name: "Star",       emoji: "⭐", sound: "Gold star!"),
        ThemeEntry(name: "Diamond",    emoji: "💎", sound: "Sparkle!"),
        ThemeEntry(name: "Heart",      emoji: "💜", sound: "Purple heart!"),
        ThemeEntry(name: "Lightning",  emoji: "⚡", sound: "Zap!"),
        ThemeEntry(name: "Fire",       emoji: "🔥", sound: "Whoosh!"),
    ]

    static func themeEntries(for theme: ThemeType) -> [ThemeEntry] {
        switch theme {
        case .animals:      return animalTheme
        case .vehicles:     return vehicleTheme
        case .musical:      return musicalTheme
        case .baby:         return babyTheme
        case .highContrast: return highContrastTheme
        }
    }
}
