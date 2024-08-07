//
//  PatternManager.swift
//  HanYoungHater
//
//  Created by Ted Kim on 8/6/24.
//
/* Json DB에서 데이터를 가져오지 못했을 경우, 기본 패턴을 로드함 */
// 데이터 기본 구조
// [ output : [ input : delete ]
// [ 대체어 : [ 입력된 문자열을 1char씩 입력받은 결과 : 삭제(대체)할 문자열의 글자수를 맞추기 위해 대체할 문자열 ]
// e.g. slack : ["ㄴㅣㅁㅊㅏ" : "님ㅊㅏ"] // '님'은 delete 한 번으로 삭제됨

import Foundation

class PatternManager: ObservableObject {
    var dbUrl = "https://my-json-server.typicode.com/DongHyunTedKim/NimchaDB/db"
    @Published var patterns: [String: [String: String]] = [:]
    @Published var err: String = ""
    
    func loadPatternsFromServer() {
        guard let url = URL(string: dbUrl) else {
            print("Invalid URL")
            
            // 기본 패턴을 로드함
            self.patterns = patterns_default
            print("JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다.")
            err = "Invalid URL"
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching patterns: \(error)")

                // 기본 패턴을 로드함
                self.patterns = patterns_default
                print("JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다.")
                self.err = "Error fetching patterns"
                return
            }
            
            guard let data = data else {
                print("No data fetched")
                
                // 기본 패턴을 로드함
                self.patterns = patterns_default
                print("JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다.")
                self.err = "No data fetched"
                return
            }
            
            do {
                // JSON 데이터를 디코딩한 후, 배열 형태의 데이터를 딕셔너리로 변환
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [[Any]]] {
                    var combinedPatterns = [String: [String: String]]()
                    
                    for (key, array) in json where key.starts(with: "data") {
                        let patterns = convertToDictionary(array: array)
                        combinedPatterns.merge(patterns) { (current, _) in current }
                    }
                    
                    DispatchQueue.main.async {
                        self.patterns = combinedPatterns
                        print("Patterns successfully loaded")
                    }
                } else {
                    // 기본 패턴을 로드함
                    print("JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다.")
                    self.err = "Unexpected JSON format"
                    self.patterns = patterns_default
                }
            } catch {
                // 기본 패턴을 로드함
                self.patterns = patterns_default
                print("JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다. Error decoding JSON: \(error)")
                self.err = "Error decoding JSON"
            }
        }
        
        task.resume()
    }
}

// 주어진 배열 데이터를 [String: [String: String]] 형식으로 변환하는 함수
func convertToDictionary(array: [[Any]]) -> [String: [String: String]] {
    var result = [String: [String: String]]()
    
    for item in array {
        if let platform = item[0] as? String,
           let key = item[1] as? String,
           let value = item[2] as? String {
            result[platform] = [key: value]
        }
    }
    
    return result
}

// 변환된 딕셔너리
var patterns_default: [String: [String: String]] = [
    "slack" : ["ㄴㅣㅁㅊㅏ": "님ㅊㅏ"],
    "notion" : ["ㅜㅐㅅㅑㅐㅜ": "ㅜㅐ샤ㅐㅜ"],
    "youtube" : ["ㅛㅐㅕㅅㅕㅠㄷ": "ㅛㅐㅕ셔ㅠㄷ"],
    "chrome" : ["ㅊㅗㄱㅐㅡㄷ" : "초개ㅡㄷ"],
    "safari" : ["ㄴㅁㄹㅁㄱㅑ" : "ㄴㅁㄹㅁㄱㅑ"],
    "cyworld" : ["ㅊㅛㅈㅐㄱㅣㅇ" : "쵸재기ㅇ"],
    "kakao" : ["ㅏㅁㅏㅁㅐ" : "ㅏ마매"],
    //
    "tele" : ["ㅅㄷㅣㄷ" : "ㅅ디ㄷ"], // for telegram
    "ever" : ["ㄷㅍㄷㄱ" : "ㄷㅍㄷㄱ"],
    "twit" : ["ㅅㅈㅑㅅ" : "ㅅ쟛ㅅ"], // for twitter
    "insta" : ["ㅑㅜㄴㅅㅁ" : "ㅑㅜㄴㅅㅁ"], // for instagram
    "face" : ["ㄹㅁㅊㄷ" : "ㄹㅁㅊㄷ"],
    "naver" : ["ㅜㅁㅍㄷㄱ" : "ㅜㅁㅍㄷㄱ"],
    "google" : ["ㅎㅐㅐㅎㅣㄷ" : "해ㅐ히ㄷ"],
    "apple" : ["ㅁㅔㅔㅣㄷ" : "메ㅔㅣㄷ"],
    "netfl" : ["ㅜㄷㅅㄹㅣ" : "ㅜㄷㅅㄹㅣ"], // for netflix
    "disney" : ["ㅇㅑㄴㅜㄷㅛ" : "야누ㄷㅛ"], // for disney
    "music" : ["ㅡㅕㄴㅑㅊ" : "ㅡㅕ냐ㅊ"],
    "amazon" : ["ㅁㅡㅁㅋㅐㅜ" : "믐캐ㅜ"],
    "fire" : ["ㄹㅑㄱㄷ" : "략ㄷ"], // for firefox
    "xcode" : ["ㅌㅊㅐㅇㄷ" : "ㅌ챙ㄷ"],
    "vscode" : ["ㅍㄴㅊㅐㅇㄷ" : "ㅍㄴ챙ㄷ"],
    "key" : ["ㅏㄷㅛ" : "ㅏㄷㅛ"], // for keynote
    "power" : ["ㅔㅐㅈㄷㄱ" : "ㅔㅐㅈㄷㄱ"],
    "word" : ["ㅈㅐㄱㅇ" : "잭ㅇ"],
    "excel" : ["ㄷㅌㅊㄷㅣ" : "ㄷㅌㅊㄷㅣ"],
    "numbers" : ["ㅜㅕㅡㅠㄷㄱㄴ" : "ㅜㅕㅡㅠㄷㄱㄴ"],
    "memo" : ["ㅡㄷㅡㅐ" : "ㅡ드ㅐ"],
    "teams" : ["ㅅㄷㅁㅡㄴ" : "ㅅㄷ므ㄴ"],
    "zoom" : ["ㅋㅐㅐㅡ" : "캐ㅐㅡ"],
    "nate" : ["ㅜㅁㅅㄷ" : "ㅜㅁㅅㄷ"],
    
    "pip" : ["ㅔㅑㅔ" : "ㅔㅑㅔ"],
    "root" : ["ㄱㅐㅐㅅ" : "개ㅐㅅ"],
    "sudo" : ["ㄴㅕㅇㅐ" : "녀ㅇㅐ"],
    "trans" : ["ㅅㄱㅁㅜㄴ" : "ㅅㄱ무ㄴ"],
    "true" : ["ㅅㄱㅕㄷ" : "ㅅ겨ㄷ"],
    "false" : ["ㄹㅁㅣㄴㄷ" : "ㄹ민ㄷ"],
    // "for" : ["ㄹㅐㄱ" : "래ㄱ"], // '랙'은 가끔 사용될 수 있다고 보여짐
]
