import SwiftUI

struct ContentView: View {
    @ObservedObject var appDelegate: AppDelegate
    
    @State private var testInput = ""
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            Text("HanYoungHater")
                .font(.largeTitle)
                .padding()
            
            Toggle("자동 전환 켜기", isOn: $appDelegate.isAutoConvertOn)
                .padding()
            
            Text("현재 입력 소스: \(appDelegate.currentInputSource)")
                .padding()
            
            TextField("여기에 테스트 텍스트를 입력하세요", text: $testInput)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                // 타이핑될때마다 한영확인
                .onChange(of: testInput) { newValue in
                    appDelegate.updateCurrentInputSource()
                }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            showingAlert = true
            appDelegate.updateCurrentInputSource() // 화면이 나타날 때 현재 입력 소스를 초기화합니다.
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("접근성 권한 필요"),
                message: Text("앱이 정상적으로 동작하려면 접근성 권한이 필요합니다. 시스템 환경설정 > 보안 및 개인 정보 보호 > 접근성에서 권한을 설정해주세요."),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(appDelegate: AppDelegate())
    }
}
