import Foundation

enum AnswerSlot: String, Codable {
    case phrase     // default: any noun phrase, including its determiner ("a banana", "the void")
    case noun       // singular noun without article (article precedes §): "lion", "wizard"
    case adjective  // "fast", "loud"
    case verb       // bare infinitive: "dance", "vanish"
}

struct BotAnswerPool: Decodable {
    var phrase: [String] = []
    var noun: [String] = []
    var adjective: [String] = []
    var verb: [String] = []

    func answers(for slot: AnswerSlot) -> [String] {
        let primary: [String]
        switch slot {
        case .phrase:    primary = phrase
        case .noun:      primary = noun
        case .adjective: primary = adjective
        case .verb:      primary = verb
        }
        return primary.isEmpty ? phrase : primary
    }
}

enum LocalizedContent {

    /// Currently active language code, falling back to English.
    static var languageCode: String {
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        let base = preferred.split(separator: "-").first.map(String.init) ?? "en"
        return ["fr", "en"].contains(base) ? base : "en"
    }

    static func presets() -> [String] {
        loadStringArray(named: "presets")
    }

    static func botAnswerPool() -> BotAnswerPool {
        let lang = languageCode
        let candidates = ["botAnswers-\(lang)", "botAnswers-en", "botAnswers"]
        for candidate in candidates {
            guard let url = Bundle.main.url(forResource: candidate, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { continue }
            if let pool = try? JSONDecoder().decode(BotAnswerPool.self, from: data) {
                return pool
            }
            if let arr = try? JSONDecoder().decode([String].self, from: data) {
                // Legacy flat-array format
                return BotAnswerPool(phrase: arr, noun: [], adjective: [], verb: [])
            }
        }
        return BotAnswerPool()
    }

    static func botNames() -> [String] {
        loadStringArray(named: "botNames")
    }

    private static func loadStringArray(named base: String) -> [String] {
        let lang = languageCode
        let candidates = [
            "\(base)-\(lang)",
            "\(base)-en",
            base
        ]
        for candidate in candidates {
            if let url = Bundle.main.url(forResource: candidate, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let arr = try? JSONDecoder().decode([String].self, from: data) {
                return arr
            }
        }
        return []
    }
}

enum SlotClassifier {

    /// Heuristic slot classifier — looks at words on either side of §.
    /// Optimizes for high-precision; falls through to `.phrase` when uncertain.
    static func classify(_ sentence: String, language: String) -> AnswerSlot {
        guard let range = sentence.range(of: "§") else { return .phrase }
        let before = String(sentence[..<range.lowerBound])
        let after = String(sentence[range.upperBound...])
        let beforeLower = before.lowercased()
        let afterTrimmed = after.trimmingCharacters(in: .whitespacesAndNewlines)
        let afterStartsWithPunct = afterTrimmed.first.map { ".,!?;:".contains($0) } ?? true

        let beforeTokens = beforeLower
            .split(whereSeparator: { !$0.isLetter && $0 != "'" })
            .map(String.init)
        let lastBefore = beforeTokens.last ?? ""

        let afterTokens = afterTrimmed
            .split(whereSeparator: { !$0.isLetter && $0 != "'" })
            .map(String.init)
        let firstAfter = (afterTokens.first ?? "").lowercased()

        let articles: Set<String>
        if language == "en" {
            articles = ["a", "an", "the"]
        } else {
            articles = ["un", "une", "le", "la", "les", "des", "du",
                        "ma", "mon", "mes", "ta", "ton", "tes",
                        "sa", "son", "ses", "notre", "nos", "votre", "vos",
                        "leur", "leurs"]
        }

        let copulas: Set<String>
        if language == "en" {
            copulas = ["is", "are", "was", "were", "be", "been", "being",
                       "feel", "feels", "felt", "seem", "seems", "seemed"]
        } else {
            copulas = ["est", "sont", "était", "etait", "étaient", "etaient",
                       "suis", "es", "êtes", "etes", "sommes", "être", "etre",
                       "semble", "paraît", "parait"]
        }

        // Words after § that don't count as the start of a noun phrase
        let stopAfter: Set<String> = [
            // Conjunctions
            "and", "or", "but", "et", "ou", "mais",
            // Prepositions (EN + FR)
            "of", "with", "in", "on", "at", "for", "from", "by", "to", "about",
            "de", "du", "des", "à", "a", "au", "aux", "avec", "dans", "sur",
            "pour", "par", "vers", "chez", "sous", "sans", "selon",
            // Object/reflexive/relative pronouns (FR + EN)
            "me", "te", "se", "lui", "y", "en",
            "qui", "que", "dont", "où",
            "who", "which", "that"
        ]

        // ---------------------------------------------------------------
        // 1. Verb (bare infinitive)
        // ---------------------------------------------------------------
        if language == "en" && beforeLower.hasSuffix("to ") {
            return .verb
        }
        if language == "fr" {
            // "X de §[end]" where X is a noun/idiom that takes an infinitive
            if afterStartsWithPunct || afterTrimmed.isEmpty {
                let frVerbCues: Set<String> = [
                    "envie", "reve", "rêve", "facon", "façon",
                    "manière", "maniere", "afin", "besoin", "peur",
                    "fier", "fière", "fiere", "moyen", "occasion",
                    "histoire", "raison", "remède", "remede",
                    "façons", "facons", "manières", "manieres", "moyens"
                ]
                let lastTwo = beforeTokens.suffix(2)
                if lastTwo.last == "de", let prev = lastTwo.dropLast().last,
                   frVerbCues.contains(prev) {
                    return .verb
                }
                if beforeTokens.suffix(3).joined(separator: " ").hasSuffix("est de") {
                    return .verb
                }
            }
            // "[verb-loving] § et [infinitive]" → § is verb (parallel infinitive)
            let verbLovingFR: Set<String> = [
                "aiment", "aime", "aimes", "adore", "adorent", "adores",
                "veut", "veulent", "veux", "voudrait", "voudraient",
                "préfère", "prefere", "préfèrent", "preferent",
                "savent", "sait", "peut", "peuvent", "doit", "doivent"
            ]
            if verbLovingFR.contains(lastBefore),
               afterTokens.count >= 2, afterTokens[0] == "et" {
                let next = afterTokens[1]
                if next.hasSuffix("er") || next.hasSuffix("ir") || next.hasSuffix("re") {
                    return .verb
                }
            }
        }

        // ---------------------------------------------------------------
        // 2. Article immediately before §
        // ---------------------------------------------------------------
        if articles.contains(lastBefore) {
            if afterStartsWithPunct || afterTrimmed.isEmpty {
                return .noun
            }
            if !firstAfter.isEmpty && !stopAfter.contains(firstAfter) {
                return .adjective
            }
            // article + § + stop-word (preposition, pronoun, conjunction) → noun
            return .noun
        }

        // ---------------------------------------------------------------
        // 3. Predicate after copula: "are § and X", "est § et X", "sont § dans Y"
        // ---------------------------------------------------------------
        if copulas.contains(lastBefore) {
            if firstAfter == "and" || firstAfter == "et"
                || firstAfter == "ou" || firstAfter == "or" {
                return .adjective
            }
            // "X is § in/for/with Y" → predicate adjective + modifier
            let predicateModifierPreps: Set<String> = [
                "dans", "in", "envers", "towards",
                "pour", "for", "avec", "with",
                "sur", "on", "à", "to", "au", "aux", "comme", "as"
            ]
            if predicateModifierPreps.contains(firstAfter) {
                return .adjective
            }
            if afterStartsWithPunct || afterTrimmed.isEmpty {
                return .phrase
            }
        }

        // ---------------------------------------------------------------
        // 4. Backtrack: "[article] [adjective] §[end]" → noun
        //    e.g. "I would be a fast §.", "un bon §."
        //    Window of 3 keeps this from misfiring on long sentences where
        //    an article applies to an earlier noun ("...the hole and saw §").
        // ---------------------------------------------------------------
        if afterStartsWithPunct || afterTrimmed.isEmpty {
            let window = Array(beforeTokens.suffix(3))
            let articleIdx = window.lastIndex(where: { articles.contains($0) })
            let copulaIdx = window.lastIndex(where: { copulas.contains($0) })
            if let aIdx = articleIdx,
               (copulaIdx == nil || aIdx > copulaIdx!),
               !articles.contains(lastBefore),
               !copulas.contains(lastBefore) {
                return .noun
            }
        }

        // ---------------------------------------------------------------
        // 4b. Subject-of-copula: "[article] ... [adj] § est/is ..." → noun
        //     Triggered when § is mid-sentence and followed by a copula.
        // ---------------------------------------------------------------
        if copulas.contains(firstAfter) {
            let window = Array(beforeTokens.suffix(5))
            if window.contains(where: { articles.contains($0) }),
               !articles.contains(lastBefore),
               !copulas.contains(lastBefore) {
                return .noun
            }
        }

        // ---------------------------------------------------------------
        // 5. FR: "[noun] de §[end]" → noun (when not caught by verb rule)
        //    e.g. "morceaux de §.", "alimentées par de §."
        // ---------------------------------------------------------------
        if language == "fr",
           lastBefore == "de",
           (afterStartsWithPunct || afterTrimmed.isEmpty) {
            return .noun
        }

        // ---------------------------------------------------------------
        // 6. EN: compound-noun position: "follow safety §.", "respect speed §."
        // ---------------------------------------------------------------
        if language == "en", afterStartsWithPunct || afterTrimmed.isEmpty {
            let compoundCues: Set<String> = [
                "safety", "speed", "security", "school", "service", "road",
                "city", "system", "weather", "music", "movie", "book",
                "history", "nature", "rail", "train", "traffic",
                "company", "team", "highway", "fire", "health"
            ]
            if compoundCues.contains(lastBefore) {
                return .noun
            }
        }

        // ---------------------------------------------------------------
        // 7. FR post-nominal adjective: "moyen de transport §", "transport § pour …"
        // ---------------------------------------------------------------
        if language == "fr" {
            let postNominalCues: Set<String> = [
                "transport", "vitesse", "voyage", "voyages",
                "déplacements", "deplacements",
                "moment", "moments", "endroit", "lieu",
                "manière", "maniere", "façon", "facon",
                "personne", "personnes", "histoire", "musique",
                "livre", "film", "style", "genre", "mode",
                "idée", "idee"
            ]
            if postNominalCues.contains(lastBefore) {
                if afterStartsWithPunct || afterTrimmed.isEmpty { return .adjective }
                let preps: Set<String> = ["pour", "avec", "dans", "sur",
                                          "de", "du", "des",
                                          "à", "a", "au", "aux", "et", "ou"]
                if preps.contains(firstAfter) { return .adjective }
            }
        }

        return .phrase
    }
}
