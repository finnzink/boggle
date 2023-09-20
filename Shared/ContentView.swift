import SwiftUI

class TrieNode {
    var isWord = false
    var children: [Character:TrieNode] = [:]
    func addChild(char: Character, isLast: Bool) -> TrieNode {
        if children[char] != nil {
            return children[char]!
        } else {
            let newNode = TrieNode()
            children[char] = newNode
            newNode.isWord = isLast
            return newNode
        }
    }
}

extension StringProtocol {
    subscript(_ offset: Int)                     -> Element     { self[index(startIndex, offsetBy: offset)] }
    subscript(_ range: Range<Int>)               -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
    subscript(_ range: ClosedRange<Int>)         -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1)) }
    subscript(_ range: PartialRangeUpTo<Int>)    -> SubSequence { prefix(range.upperBound) }
    subscript(_ range: PartialRangeFrom<Int>)    -> SubSequence { suffix(Swift.max(0, count-range.lowerBound)) }
}

struct ContentView: View {
    @State private var location: CGPoint = CGPoint(x: 50, y: 50)
    @State private var colors: [Bool] = [true, true]
    @State var curPos: (Int, Int) = (-1, -1)
    @State var exactPos: (Int, Int) = (-1, -1)
    @State var tiles: [[String]] =
        Array(repeating: ["X", "X","X","X","X"], count: 5)
    @State var curWord: String = ""
    @State var curIsReal = false
    @State var curPath: [(Int, Int)] = []
    @State var words: [String] = []
    @State var points: Int = 0
    @State var dict: [String] = []
    @State var Trie = TrieNode()
    
    @State var timeRemaining = 120
    @State var paused = false
    
    @State var bestSolves: [String] = []
    @State var minBestSolve: Int = 4
    @State var currBestSolve: Int = -1
    
    @State var totalWords = 0
    
    @State var input: String = ""
        
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var dice: [[String]] = [
        ["Qu","B","Z","J","X","K"],
 //       ["Qu","Qu","Qu","Qu","Qu","Qu"],
        ["T","O","U","O","T","O"],
        ["O","V","W","R","G","R"],
        ["A","A","A","F","S","R"],
        ["A","U","M","E","E","G"],
        
        ["H","H","L","R","D","O"],
        ["N","H","D","T","H","O"],
        ["L","H","N","R","O","D"],
        ["A","F","A","I","S","R"],
        ["Y","I","F","A","S","R"],
        
        ["T","E","L","P","C","I"],
        ["S","S","N","S","E","U"],
        ["R","I","Y","P","R","H"],
        ["D","O","R","D","L","N"],
        ["C","C","W","N","S","T"],
        
        ["T","T","O","T","E","M"],
        ["S","C","T","I","E","P"],
        ["E","A","N","D","N","N"],
        ["M","N","N","E","A","G"],
        ["O","U","T","O","W","N"],
        
        ["A","E","A","E","E","E"],
        ["Y","I","F","P","S","R"],
        ["E","E","E","E","M","A"],
        ["I","T","I","T","I","E"],
        ["E","T","I","L","I","C"]
    ]
    
    func addBestSolve(solve: String) {
        if bestSolves.count < 10 || solve.count >= minBestSolve {
            if !bestSolves.contains(solve) {
                bestSolves.append(solve)
            }
            bestSolves.sort(by: {$0.count < $1.count})
            if bestSolves.count > 10 {
                bestSolves.remove(at: 0)
            }
            minBestSolve = bestSolves[0].count
        }
    }
    
    func checkReal(word: String) {
        // traverse dict tree
        if word == "" { curIsReal = false}
        var currNode = Trie
        for i in 0..<word.count {
            if currNode.children[word[i]] == nil {
                curIsReal = false
                return
            }
            if currNode.children[word[i]]!.isWord && i == word.count - 1 {
                curIsReal = true
                return
            }
            currNode = currNode.children[word[i]]!
        }
        curIsReal = false
    }
    
    func checkHelper(word: String, visited: [(Int,Int)]) {
        if word == "" { return }
        for i in -1...1 {
            for j in -1...1 {
                if i == 0 && j == 0 { continue }
                let xIndex = visited.last!.0 + i
                let yIndex = visited.last!.1 + j
                if xIndex < 0 || xIndex > 4 { continue }
                if yIndex < 0 || yIndex > 4 { continue }
                
                let currTile = tiles[xIndex][yIndex].lowercased()
                if currTile != word.prefix(currTile.count)
                    { continue }
                
                if visited.contains(where: { p in
                    if p == (xIndex,yIndex) {return true}
                    else {return false}} )
                    { continue }
                
                // character is a match!
                var newVisited = visited
                newVisited.append((xIndex,yIndex))
                
                if word.count == currTile.count {
                    curPath = newVisited
                    curIsReal = true
                }
                else {
                    let newWord = word.suffix(word.count - currTile.count)
                    checkHelper(word: String(newWord), visited: newVisited)
                }
            }
        }
    }
    
    func checkWord(word: String) {
        curWord = word
        curPath = []
        if word.count <= 1 {
            return
        }
        for i in 0...4 {
            for j in 0...4 {
                let currTile = tiles[i][j].lowercased()
                if currTile != word.prefix(currTile.count)
                    { continue }
                let newWord = word.suffix(word.count - currTile.count)
                checkHelper(word: String(newWord), visited: [(i,j)])
            }
        }
        checkReal(word: word)
    }
    
    func buildTrie() {
        if let filepath = Bundle.main.path(forResource: "dictionary", ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                dict = contents.components(separatedBy: "\n")
            } catch {
                // contents could not be loaded
            }
        } else {
            // example.txt not found!
        }
        print("loaded dictionary")
        for i in 0..<dict.count {
            if dict[i].count < 4 {continue}
            var curNode = Trie.addChild(char: dict[i][0], isLast: false)
            for j in 1..<dict[i].count {
                curNode = curNode.addChild(char: dict[i][j], isLast: j == dict[i].count - 1 ? true : false)
            }
        }
        print("trie formed")
    }
    
    func solveBoardHelper(path: [(Int, Int)], currWord: String, currNode: TrieNode) {
        if path.count >= 4 && currNode.isWord {
            totalWords += 1
            addBestSolve(solve: currWord)
        }
        for i in -1...1 {
            for j in -1...1 {
                if i == 0 && j == 0 { continue }
                let xIndex = path.last!.0 + i
                let yIndex = path.last!.1 + j
                if xIndex < 0 || xIndex > 4 { continue }
                if yIndex < 0 || yIndex > 4 { continue }
                if path.contains(where: { p in
                    if p == (xIndex,yIndex) {return true}
                    else {return false}})
                    { continue }
                var newPath = path
                newPath.append((xIndex, yIndex))
                let currChar: String = tiles[xIndex][yIndex].lowercased()
                var newNode : TrieNode? = currNode
                for k in 0..<currChar.count {
                    if newNode!.children[currChar[k]] == nil {
                        newNode = nil
                        break
                    }
                    else {
                        newNode = newNode!.children[currChar[k]]!
                    }
                }
                if newNode == nil { continue }
                let newWord = currWord + currChar
                if path.count < 20 {
                    solveBoardHelper(path: newPath, currWord: newWord, currNode: newNode!)
                    if newWord.contains("q") {print(newWord)}
                }
            }
        }
    }
    func solveBoard() {
        if Trie.children.isEmpty { buildTrie() }
        for i in 0...4 {
            for j in 0...4 {
                var newNode : TrieNode? = Trie
                let currChar = tiles[i][j].lowercased()
                
                for k in 0..<currChar.count {
                    if newNode!.children[currChar[k]] == nil {
                        newNode = nil
                        break
                    }
                    else {
                        newNode = newNode!.children[currChar[k]]!
                    }
                }
                if newNode == nil { continue }
                
                solveBoardHelper(path: [(i,j)], currWord: currChar, currNode: newNode!)
            }
        }
        print(bestSolves)
        print("board solved")
    }
    
    func getPoints(size: Int) -> Int {
        if size <= 4 { return 1 }
        else { return getPoints(size: size - 1) + getPoints(size: size - 2) }
    }
    
    func validMove() -> Bool {
        if curPos.0 != -1 && curPos.1 != -1
            // make sure position is new
            && !curPath.contains(where: { path in
                if path == curPos {return true}
                else {return false}
            // within one pos of prev move
            }) && (curPath.count == 0 ||
                    (abs(curPos.0 - curPath.last!.0) <= 1
                        && abs(curPos.1 - curPath.last!.1) <= 1)) {
            return true
        }
        return false
    }
    
    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                if (Int(value.location.x) - 40) % 50 < 20 && value.location.x > 40
                { curPos.0 = (Int(value.location.x) - 40) / 50 }
                else { curPos.0 = -1 }
                
                if (Int(value.location.y) - 40) % 50 < 20 && value.location.y > 40
                { curPos.1 = (Int(value.location.y) - 40) / 50 }
                else { curPos.1 = -1 }
                
                if validMove() {
                    curPath.append(curPos)
                    curWord += tiles[curPath.last?.0 ?? 0][curPath.last?.1 ?? 0]
                    checkReal(word: curWord.lowercased())
                }
                // check for backtrack
                if curPath.count > 1 && curPos == curPath[curPath.count - 2] {
                    curPath.removeLast()
                    curWord.removeLast()
                    checkReal(word: curWord.lowercased())
                }
                exactPos = (Int(value.location.x),Int(value.location.y))
            }.onEnded { _ in
                if curIsReal && !words.contains(curWord.lowercased()) && timeRemaining > 0 && curPath.count > 0
                {
                    words.append(curWord.lowercased())
                    points += getPoints(size: curWord.count)
                }
                curWord = ""
                curPath = []
            }
    }
    
    func shuffleBoard() {
        var indeces = Array(0...24)
        indeces.shuffle()
        for i in 0...4 {
            for j in 0...4 {
                let curIndex = indeces[5*i + j]
                tiles[i][j] = dice[curIndex][Int.random(in: 0..<6)]
            }
        }
        bestSolves = []
        curWord = ""
        curPath = []
        words = []
        points = 0
        totalWords = 0
        
        solveBoard()
        
        timeRemaining = 120
        currBestSolve = bestSolves.count - 1
    }
    
    var body: some View {
        
        let binding = Binding<String>(get: {
                self.input
            }, set: {
                self.input = $0
                // do whatever you want here
                checkWord(word: input.lowercased())
            })
        
        ZStack (alignment: .topLeading){
            Rectangle()
                .foregroundColor(.blue)
                .frame(width: 300, height: 300, alignment: .topLeading)
                .gesture(simpleDrag)
            
            if curPath.count > 1 {
                ForEach((1..<curPath.count), id: \.self) { i in
                    Path { path in
                        path.move(to: CGPoint(x: (curPath[i-1].0 * 50) + 50, y:(curPath[i-1].1 * 50) + 50))
                        path.addLine(to: CGPoint(x: (curPath[i].0 * 50) + 50, y:(curPath[i].1 * 50) + 50))
                    }.stroke(Color.black, lineWidth: 10)
                }
            }
            ForEach((0...4), id: \.self) { i in
                ForEach((0...4), id: \.self) { j in
                    let xval = 50*i + 50
                    let yval = 50*j + 50
                    Rectangle()
                        .frame(width: 20, height: 20)
                        .position(x: CGFloat(xval), y: CGFloat(yval))
                        .foregroundColor(.pink)
                    Text(tiles[i][j])
                        .position(x: CGFloat(xval), y: CGFloat(yval))
                }
            }
            
            VStack {
                Text("\(curWord.uppercased())")
                    .background(curIsReal ? Color.green : Color.red)
                
                Button(action: { shuffleBoard() })
                    { Text("shuffle").background(Color.white)}
                
                HStack {
                    Text("\(timeRemaining)").onReceive(timer) { _ in
                        if self.timeRemaining > 0 && !paused {
                            self.timeRemaining -= 1
                        }
                    }
                    Button(action: { paused = !paused })
                        { Text("\(paused ? "play" : "pause" )").background(Color.white)}
                    Button(action: { timeRemaining = 0 })
                        { Text("end").background(Color.white)}
                }
                HStack {
                    ForEach((0..<words.count), id: \.self) { i in
                        Text("\(words[i].uppercased()) +\(getPoints(size: words[i].count))")
                    }
                }
                Text("Points: \(points)")
                
                if (timeRemaining == 0) {
                    HStack {
                        Button(action: {
                            if bestSolves.count > 0
                                { checkWord(word: bestSolves[currBestSolve]) }
                            if currBestSolve == 0 {
                                currBestSolve = bestSolves.count - 1 }
                            else { currBestSolve -= 1 }
                        }) { Text("next solve").background(Color.white) }
                        Text("Solved: \(words.count)/\(totalWords)")
                    }
                }
                TextField(
                    "type something...",
                    text: binding,
                    onCommit: {
                        if curIsReal && !words.contains(input.lowercased())
                            && curPath.count > 0 {
                            words.append(curWord.lowercased())
                            points += getPoints(size: curWord.count)
                        }
                        input = ""
                    }
                )
            }.position(x: 200, y:400)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
