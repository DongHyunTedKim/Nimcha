//
//  Patterns.swift
//  HanYoungHater
//
//  Created by Ted Kim on 8/5/24.
//

import Foundation
// 대체어 : [입력된 문자열을 1char씩 입력받은 결과 : 삭제(대체)할 문자열의 글자수를 맞추기 위해 대체할 문자열 ]
// e.g. slack : ["ㄴㅣㅁㅊㅏ" : "님ㅊㅏ"] // '님'은 delete 한 번으로 삭제됨
var patterns: [String: [String: String]] = [
    "slack" : ["ㄴㅣㅁㅊㅏ": "님ㅊㅏ"],
    "notion" : ["ㅜㅐㅅㅑㅐㅜ": "ㅜㅐ샤ㅐㅜ"],
    "youtube" : ["ㅛㅐㅕㅅㅕㅠㄷ": "ㅛㅐㅕ셔ㅠㄷ"],
    "chrome" : ["ㅊㅗㄱㅐㅡㄷ" : "초개ㅡㄷ"],
    "safari" : ["ㄴㅁㄹㅁㄱㅑ" : "ㄴㅁㄹㅁㄱㅑ"],
    "cyworld" : ["ㅊㅛㅈㅐㄱㅣㅇ" : "쵸재기ㅇ"],
]



// kakao
// telegram
// evernote
// twitter
// instagram
// facebook
// naver
// google
// apple
// netflix
// music
// amazon
// apple
// firefox
// xcode
// vscode
// keynote
// powerpoint
// word
// excel
// numbers
// memo
// teams
// zoom
