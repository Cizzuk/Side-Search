//
//  SearchEnginePresets.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation

class SearchEnginePresets {
    // Copy the "url" to the URLBasedAssistantModel.
    struct Preset {
        let name: LocalizedStringResource
        let url: String
    }
    
    static var defaultSearchEngine: Preset {
        if GeoHelper.currentRegion == "CN" {
            return Preset(
                name: "百度AI搜索",
                url: "https://chat.baidu.com/search?query=%s",
            )
        } else {
            return Preset(
                name: "ChatGPT",
                url: "https://chatgpt.com/?q=%s",
            )
        }
    }
    
    static var aiAssistants: [Preset] {
        var aiCSEs: [Preset] = []
        if GeoHelper.currentRegion != "CN" {
            aiCSEs.append(contentsOf: [
                Preset(
                    name: "ChatGPT",
                    url: "https://chatgpt.com/?q=%s",
                ),
                Preset(
                    name: "Gemini",
                    url: "https://gemini.google.com/?prompt_text=%s",
                ),
                Preset(
                    name: "Claude",
                    url: "https://claude.ai/new?q=%s",
                ),
                Preset(
                    name: "Copilot Search",
                    url: "https://www.bing.com/copilotsearch?q=%s",
                ),
                Preset(
                    name: "Perplexity",
                    url: "https://www.perplexity.ai/?q=%s",
                )
            ])
        }
        
        if GeoHelper.currentRegion == "CN" || GeoHelper.containsLanguage("zh-Hans") {
            aiCSEs.append(Preset(
                name: "百度AI搜索",
                url: "https://chat.baidu.com/search?query=%s",
            ))
        }
        
        return aiCSEs
    }
    
    static var normalSearchEngines: [Preset] {
        var normalCSEs: [Preset] = []
        
        let localizedYahoo: Preset
        if GeoHelper.preferredLanguages.first == "ja-JP" {
            localizedYahoo = Preset(
                name: "Yahoo! JAPAN",
                url: "https://search.yahoo.co.jp/search?p=%s",
            )
        } else {
            localizedYahoo = Preset(
                name: "Yahoo",
                url: "https://search.yahoo.com/search?p=%s",
            )
        }
        
        normalCSEs.append(contentsOf:[
            Preset(
                name: "Google",
                url: "https://www.google.com/search?q=%s&client=safari",
            ),
            Preset(
                name: "Bing",
                url: "https://www.bing.com/search?q=%s",
            ),
            localizedYahoo,
            Preset(
                name: "DuckDuckGo",
                url: "https://duckduckgo.com/?q=%s",
            ),
            Preset(
                name: "Ecosia",
                url: "https://www.ecosia.org/search?q=%s",
            ),
        ])
        
        if GeoHelper.currentRegion == "CN" || GeoHelper.containsLanguage("zh-Hans") {
            normalCSEs.append(Preset(
                name: "百度",
                url: "https://www.baidu.com/s?wd=%s",
            ))
        }
        
        if GeoHelper.currentRegion == "RU" || GeoHelper.containsLanguage("ru") {
            normalCSEs.append(Preset(
                name: "Яндекс",
                url: "https://yandex.ru/search/?text=%s",
            ))
        }
        
        normalCSEs.append(contentsOf:[
            Preset(
                name: "Startpage",
                url: "https://www.startpage.com/sp/search?query=%s",
            ),
            Preset(
                name: "Brave Search",
                url: "https://search.brave.com/search?q=%s",
            ),
            Preset(
                name: "Kagi",
                url: "https://kagi.com/search?q=%s",
            ),
        ])
        
        return normalCSEs
    }
}
