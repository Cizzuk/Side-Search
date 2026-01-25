//
//  SearchEnginePresets.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation

class SearchEnginePresets {
    // Helpers
    private static let currentRegion = Locale.current.region?.identifier
    private static let preferredLanguages = Locale.preferredLanguages
    
    private static func containsLanguage(_ languageCode: String) -> Bool {
        return preferredLanguages.contains { language in
            if language.hasPrefix(languageCode + "-") {
                return true
            }
            let locale = Locale(identifier: language)
            return locale.language.languageCode?.identifier == languageCode
        }
    }
    
    static var defaultSearchEngine: URLBasedAssistantModel {
        if currentRegion == "CN" {
            return URLBasedAssistantModel(
                name: "百度AI搜索",
                url: "https://chat.baidu.com/search?query=%s",
            )
        } else {
            return URLBasedAssistantModel(
                name: "ChatGPT",
                url: "https://chatgpt.com/?q=%s",
            )
        }
    }
    
    static var aiAssistants: [URLBasedAssistantModel] {
        var aiCSEs: [URLBasedAssistantModel] = []
        if currentRegion != "CN" {
            aiCSEs.append(contentsOf: [
                URLBasedAssistantModel(
                    name: "ChatGPT",
                    url: "https://chatgpt.com/?q=%s",
                ),
                URLBasedAssistantModel(
                    name: "Gemini",
                    url: "https://gemini.google.com/?prompt_text=%s",
                ),
                URLBasedAssistantModel(
                    name: "Claude",
                    url: "https://claude.ai/new?q=%s",
                ),
                URLBasedAssistantModel(
                    name: "Copilot Search",
                    url: "https://www.bing.com/copilotsearch?q=%s",
                ),
                URLBasedAssistantModel(
                    name: "Perplexity",
                    url: "https://www.perplexity.ai/?q=%s",
                )
            ])
        }
        
        if currentRegion == "CN" || containsLanguage("zh-Hans") {
            aiCSEs.append(URLBasedAssistantModel(
                name: "百度AI搜索",
                url: "https://chat.baidu.com/search?query=%s",
            ))
        }
        
        return aiCSEs
    }
    
    static var normalSearchEngines: [URLBasedAssistantModel] {
        var normalCSEs: [URLBasedAssistantModel] = []
        
        let localizedYahoo: URLBasedAssistantModel
        if preferredLanguages.first == "ja-JP" {
            localizedYahoo = URLBasedAssistantModel(
                name: "Yahoo! JAPAN",
                url: "https://search.yahoo.co.jp/search?p=%s",
            )
        } else {
            localizedYahoo = URLBasedAssistantModel(
                name: "Yahoo",
                url: "https://search.yahoo.com/search?p=%s",
            )
        }
        
        normalCSEs.append(contentsOf:[
            URLBasedAssistantModel(
                name: "Google",
                url: "https://www.google.com/search?q=%s&client=safari",
            ),
            URLBasedAssistantModel(
                name: "Bing",
                url: "https://www.bing.com/search?q=%s",
            ),
            localizedYahoo,
            URLBasedAssistantModel(
                name: "DuckDuckGo",
                url: "https://duckduckgo.com/?q=%s",
            ),
            URLBasedAssistantModel(
                name: "Ecosia",
                url: "https://www.ecosia.org/search?q=%s",
            ),
        ])
        
        if currentRegion == "CN" || containsLanguage("zh-Hans") {
            normalCSEs.append(URLBasedAssistantModel(
                name: "百度",
                url: "https://www.baidu.com/s?wd=%s",
            ))
        }
        
        if currentRegion == "RU" || containsLanguage("ru") {
            normalCSEs.append(URLBasedAssistantModel(
                name: "Яндекс",
                url: "https://yandex.ru/search/?text=%s",
            ))
        }
        
        normalCSEs.append(contentsOf:[
            URLBasedAssistantModel(
                name: "Startpage",
                url: "https://www.startpage.com/sp/search?query=%s",
            ),
            URLBasedAssistantModel(
                name: "Brave Search",
                url: "https://search.brave.com/search?q=%s",
            ),
            URLBasedAssistantModel(
                name: "Kagi",
                url: "https://kagi.com/search?q=%s",
            ),
        ])
        
        return normalCSEs
    }
}
