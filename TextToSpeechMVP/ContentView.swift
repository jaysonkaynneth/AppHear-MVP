//
//  ContentView.swift
//  TextToSpeechMVP
//
//  Created by Ganesh Ekatata Buana on 29/09/22.
//

import Foundation
import SwiftUI
import CoreData
import Speech
import UniformTypeIdentifiers
import NaturalLanguage

//public struct TextStyle {
//    // This type is opaque because it exposes NSAttributedString details and requires unique keys.
//    // It can be extended, however, by using public static methods.
//    // Properties are internal to be accessed by StyledText
//    internal let key: NSAttributedString.Key
//    internal let apply: (Text) -> Text
//    private init(key: NSAttributedString.Key, apply: @escaping (Text) -> Text) {
//        self.key = key
//        self.apply = apply
//    }
//}
//
//// Public methods for building styles
//public extension TextStyle {
//
//    static func foregroundColor(_ color: Color) -> TextStyle {
//        TextStyle(key: .init("TextStyleForegroundColor"), apply: { $0.foregroundColor(color) })
//    }
//
//    static func regular() -> TextStyle {
//        TextStyle(key: .init("TextStyleRegular"), apply: { $0.fontWeight(.ultraLight) })
//    }
//
//    static func bold() -> TextStyle {
//        TextStyle(key: .init("TextStyleBold"), apply: { $0.bold() })
//    }
//}
//
//public struct StyledText {
//    // This is a value type. Don't be tempted to use NSMutableAttributedString here unless
//    // you also implement copy-on-write.
//    private var attributedString: NSAttributedString
//
//        private init(attributedString: NSAttributedString) {
//            self.attributedString = attributedString
//        }
//
//        public func style<S>(_ style: TextStyle,
//                             ranges: (String) -> S) -> StyledText
//            where S: Sequence, S.Element == Range<String.Index>?  //  <-- HERE
//        {
//
//            // Remember this is a value type. If you want to avoid this copy,
//            // then you need to implement copy-on-write.
//            let newAttributedString = NSMutableAttributedString(attributedString: attributedString)
//
//            for range in ranges(attributedString.string).compactMap({ $0 }) {    //  <-- HERE
//                let nsRange = NSRange(range, in: attributedString.string)
//                newAttributedString.addAttribute(style.key, value: style, range: nsRange)
//            }
//
//            return StyledText(attributedString: newAttributedString)
//        }
//}
//
//public extension StyledText {
//    // A convenience extension to apply to a single range.
//    func style(_ style: TextStyle,
//               range: (String) -> Range<String.Index> = { $0.startIndex..<$0.endIndex }) -> StyledText {
//        self.style(style, ranges: { [range($0)] })
//    }
//}
//
//extension StyledText {
//    public init(verbatim content: String, styles: [TextStyle] = [.foregroundColor(.red), .bold()]) {
//        let attributes = styles.reduce(into: [:]) { result, style in
//            result[style.key] = style
//        }
//        attributedString = NSMutableAttributedString(string: content, attributes: attributes)
//    }
//}
//
//extension StyledText: View {
//    public var body: some View { text() }
//
//    public func text() -> Text {
//        var text: Text = Text(verbatim: "")
//        attributedString
//            .enumerateAttributes(in: NSRange(location: 0, length: attributedString.length),
//                                 options: [])
//            { (attributes, range, _) in
//                let string = attributedString.attributedSubstring(from: range).string
//                let modifiers = attributes.values.map { $0 as! TextStyle }
//                text = text + modifiers.reduce(Text(verbatim: string)) { segment, style in
//                    style.apply(segment)
//                }
//        }
//        return text
//    }
//}
//
//extension TextStyle {
//    static func highlight() -> TextStyle { .foregroundColor(.black) }
//}

extension String {

    func lemmatized() -> String {
        
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [.indonesian]
        
        let tagger = NLTagger(tagSchemes: [.lemma, .language])
        tagger.string = self

        var result = [String]()

        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .lemma) { tag, tokenRange in
            let stemForm = tag?.rawValue ?? String(self[tokenRange])
            result.append(stemForm)
            return true
        }

        return result.joined()
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "id-ID"))
    
    @State var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    @State var recognitionTask         : SFSpeechRecognitionTask?
    @State var defaultTaskHint: SFSpeechRecognitionTaskHint?
    
    let audioEngine             = AVAudioEngine()

    @State private var transcript: String = "Transcript will appear here."
    @State private var isRecording: Bool = false
    @State private var showingExporter = false
    
    @State var confirmedText: AttributedString = ""
    
    let searchWords = ["makan", "minum", "tendang", "buat", "guling", "lepas"]
    
    struct TextFile: FileDocument {
        static var readableContentTypes = [UTType.plainText]
            var text: String = ""

            init(text: String) {
                self.text = text
            }

            init(configuration: ReadConfiguration) throws {
                if let data = configuration.file.regularFileContents {
                    text = String(decoding: data, as: UTF8.self)
                }
            }

            func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
                let data = Data(text.utf8)
                return FileWrapper(regularFileWithContents: data)
            }
    }
    
    func highlightText(){
        confirmedText = ""
        
        let transcriptWords = transcript.components(separatedBy: " ")
        
        for word in transcriptWords {
            
            let attributedString: AttributedString = AttributedString(word)
            var isMatched = false
            
            for searchw in searchWords{
                var attributedWord: AttributedString = AttributedString(searchw)
               
                if word.contains(searchw){
                    var container = AttributeContainer()
                    container.foregroundColor = .black
                    container.backgroundColor = .orange
                    attributedWord.mergeAttributes(container)
                    confirmedText += AttributedString(" ") + attributedWord
                    isMatched = true
                }
                
            }
            
            if isMatched == false{
            confirmedText += AttributedString(" ") + attributedString
            }
        }
    }
    
   
    
    var body: some View {
        NavigationView {
            VStack{
                
//                StyledText(verbatim: transcript).style(.highlight(), ranges: { [$0.range(of: "di"), $0.range(of: "me")] }).style(.regular(), ranges: { [$0.range(of: "di"), $0.range(of: "me"), $0.range(of: "ter", options: .init(arrayLiteral: .caseInsensitive, .regularExpression))] })
                
                
//                Text(transcript.lemmatized())
                
                
                if (UserDefaults.standard.string(forKey: "color") == "hitam"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded))
                }
                else if (UserDefaults.standard.string(forKey: "color") == "biru"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded)).foregroundColor(.blue)
                }
                else if (UserDefaults.standard.string(forKey: "color") == "merah"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded)).foregroundColor(.red)
                }
                else if (UserDefaults.standard.string(forKey: "color") == "hijau"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded)).foregroundColor(.green)
                }
                else if (UserDefaults.standard.string(forKey: "color") == "kuning"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded)).foregroundColor(.yellow)
                }
                else if (UserDefaults.standard.string(forKey: "color") == "ungu"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded)).foregroundColor(.purple)
                }
                else if (UserDefaults.standard.string(forKey: "color") == "abu"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded)).foregroundColor(.gray)
                }
                else if (UserDefaults.standard.string(forKey: "color") == "jingga"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded)).foregroundColor(.orange)
                }
                else if (UserDefaults.standard.string(forKey: "color") == "coklat"){
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded)).foregroundColor(.brown)
                }
                else {
                    Text(transcript).font(.system(size: 18, weight: .regular, design: .rounded))
                }

                HStack{
                    Text("Locale:")
                    
                    Picker("Speech Recognition Locale?", selection: $speechRecognizer) {
                                    Text("Indonesia").tag(SFSpeechRecognizer(locale: Locale.init(identifier: "id-ID")))
                                    Text("English").tag(SFSpeechRecognizer(locale: Locale.init(identifier: "en-EN")))
                                }
                    .pickerStyle(.menu)
                }
                
                if(isRecording == false){
                    Button(action: {buttonAction()}){
                        ZStack{
                            Rectangle().foregroundColor(.blue)
                            Text("Start Recording").foregroundColor(.white).font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                    }.frame(width: 130, height: 40, alignment: .center).cornerRadius(16)
                }
                
                else{
                    Button(action: {buttonAction()}){
                        ZStack{
                            Rectangle().foregroundColor(.red)
                            Text("Stop Recording").foregroundColor(.white).font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                    }.frame(width: 130, height: 40, alignment: .center).cornerRadius(16)
                }
                
                Button(action: {
                    self.showingExporter.toggle()
                }){
                    ZStack{
                        Rectangle().foregroundColor(.orange)
                        Text("Export Transcript").foregroundColor(.white).font(.system(size: 14, weight: .medium, design: .rounded))
                    }.frame(width: 130, height: 40, alignment: .center).cornerRadius(16)
                }

                Text(confirmedText)
                
            }.frame(width: 300, height: 600, alignment: .center).foregroundColor(.black)
        }.fileExporter(isPresented: $showingExporter, document: TextFile(text: transcript), contentType: .plainText) { result in
            switch result {
                case .success(let url):
                    print("Saved to \(url)")
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }


}
    
    func buttonAction(){
        highlightText()
        setupSpeech()
        if audioEngine.isRunning {
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            isRecording = false
        } else {
            self.startRecording()
        }
    }
    
    
    func setupSpeech() {

        isRecording = false
//        self.speechRecognizer?.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

            var isButtonEnabled = false

            switch authStatus {
            case .authorized:
                isButtonEnabled = true

            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")

            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")

            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            @unknown default:
                fatalError()
            }

            OperationQueue.main.addOperation() {
                isRecording = isButtonEnabled
            }
        }
    }
    
        func startRecording() {
  
        // Clear all previous session data and cancel task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Create instance of audio session to record voice
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        self.defaultTaskHint = .unspecified
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true
//            recognitionRequest.taskHint.addsPunctuation = true
        
        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false

            if result != nil {

                transcript = result?.bestTranscription.formattedString ?? "No transcript is made"
                isFinal = (result?.isFinal)!
            }

            if error != nil || isFinal {

                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                isRecording = false
                
            }
            
            if (transcript.lowercased() == "ganti warna teks menjadi biru"){
                UserDefaults.standard.set("biru", forKey: "color")
            }
            else if (transcript.lowercased() == "ganti warna teks menjadi merah"){
                UserDefaults.standard.set("merah", forKey: "color")
            }
            else if (transcript.lowercased() == "ganti warna teks menjadi hijau"){
                UserDefaults.standard.set("hijau", forKey: "color")
            }
            else if (transcript.lowercased() == "ganti warna teks menjadi kuning"){
                UserDefaults.standard.set("kuning", forKey: "color")
            }
            else if (transcript.lowercased() == "ganti warna teks menjadi ungu"){
                UserDefaults.standard.set("ungu", forKey: "color")
            }
            else if (transcript.lowercased() == "ganti warna teks menjadi abu-abu"){
                UserDefaults.standard.set("abu", forKey: "color")
            }
            else if (transcript.lowercased() == "ganti warna teks menjadi jingga"){
                UserDefaults.standard.set("jingga", forKey: "color")
            }
            else if (transcript.lowercased() == "ganti warna teks menjadi coklat"){
                UserDefaults.standard.set("coklat", forKey: "color")
            }
            else if (transcript.lowercased() == "ganti warna teks menjadi hitam"){
                UserDefaults.standard.set("hitam", forKey: "color")
            }
            
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        self.audioEngine.prepare()

        do {
            try self.audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

        transcript = "Recording speech.."
    }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
    
}
