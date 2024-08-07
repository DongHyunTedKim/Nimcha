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
    @Published var err: String = "no error"
    
    func loadPatternsFromServer() {
        guard let url = URL(string: dbUrl) else {
            // 기본 패턴을 로드함
            print("Invalid URL: JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다.")
            self.err = "Invalid URL"
            self.patterns = patterns_default
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {
                // 기본 패턴을 로드함
                print("Error fetching patterns: JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다.")
                self.err = "Error fetching patterns"
                self.patterns = patterns_default
                
                return
            }
            
            guard let data = data else {
                // 기본 패턴을 로드함
                print("No data fetched: JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다.")
                self.err = "No data fetched"
                self.patterns = patterns_default
                return
            }
            
            do {
                // JSON 데이터를 디코딩한 후, 배열 형태의 데이터를 딕셔너리로 변환
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [[Any]]] {
                    var combinedPatterns = [String: [String: String]]()
                    
                    // 30개씩 쪼개져있는 data1, data2, ...를 하나로 합침
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
                    print("Unexpected JSON format: JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다.")
                    self.err = "Unexpected JSON format"
                    self.patterns = patterns_default
                }
            } catch {
                // 기본 패턴을 로드함
                print("Error decoding JSON: JsonDB에서 데이터를 가져오지 못했습니다. 기본 패턴을 로드합니다. Error decoding JSON: \(error)")
                self.err = "Error decoding JSON"
                self.patterns = patterns_default
            }
        }
        
        task.resume()
    }
}

// 주어진 배열 데이터를 [String: [String: String]] 형식으로 변환하는 함수
func convertToDictionary(array: [[Any]]) -> [String: [String: String]] {
    var result = [String: [String: String]]()
    
    for item in array {
        if let output = item[0] as? String,
           let input = item[1] as? String,
           let delete = item[2] as? String {
            result[output] = [input: delete]
        }
    }
    
    return result
}
