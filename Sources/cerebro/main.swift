import ArgumentParser
import Foundation

struct SelectOptions: ParsableArguments {
  @Flag var numbers = false
  @Flag var punctuation = false
  @Flag var years = false
  @Flag var replacement = false
  @Flag var double = false
  @Flag var full = false
  
  @Option(name: [.customShort("i"), .long])
  var inputFile: String?
  @Option(name: [.customShort("o"), .long])
  var ouputFile: String?

}

var options = SelectOptions.parseOrExit()
var append = options.numbers || options.punctuation || options.years

if options.full || !(append || options.replacement) {
  options.numbers = true
  options.punctuation = true
  options.years = true
  options.replacement = true
  append = true
}

print(options)

if options.double {
  if !(options.replacement && append) { print("-double flag requires at least one of the append flags and the replacement flag to be set (implicitly or explicitly)."); exit(1) }
}

var pristine: Set<String> = []

if let inputFile = options.inputFile {
  let currentDir =
    URL(fileURLWithPath: inputFile.first == "/" ? "/" : FileManager.default.currentDirectoryPath, isDirectory: true)
  let inURL = currentDir.appendingPathComponent(inputFile)
  guard FileManager.default.isReadableFile(atPath: inURL.path) else {
    print("No readible file at \(inURL.path)")
    exit(2)
  }
  pristine.formUnion(try String(contentsOf: inURL).split(separator: "\n").lazy.filter { !$0.isEmpty }.map(String.init))
} else { // read from stdin
  while let nextLine = readLine(strippingNewline: true) {
    if !nextLine.isEmpty { pristine.insert(nextLine) } }
}

print("pristine: \(pristine))")

func appendNumbers(_ input: Set<String>) -> Set<String> {
  input.reduce(into: Set<String>()) { currentSet, base in
    currentSet.formUnion(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 123, 1234, 12345, 123456].map { num in "\(base)\(num)" }
    )
  }
}

func appendPunctuation(_ input: Set<String>) -> Set<String> {
  input.reduce(into: Set<String>()) { currentSet, base in
    currentSet.formUnion(
      ["!", "."].map { num in "\(base)\(num)" }
    )
  }
}

func appendYears(_ input: Set<String>) -> Set<String> {
  let currentYear = Calendar.current.component(.year, from: Date())
  return input.reduce(into: Set<String>()) { currentSet, base in
    currentSet.formUnion(
      (2000...currentYear).map { num in "\(base)\(num)" }
    )
  }
}

func replace(_ input: Set<String>) -> Set<String> {
  let aSet = input.map { str in str.replacingOccurrences(of: "a", with: "@") }
  let oSet = input.map { str in str.replacingOccurrences(of: "o", with: "0") }
  let sSet = input.map { str in str.replacingOccurrences(of: "s", with: "5") }
  var output = Set(aSet)
  output.formUnion(oSet)
  output.formUnion(sSet)
  let aoSet = aSet.map { str in str.replacingOccurrences(of: "o", with: "0") }
  output.formUnion(aoSet)
  output.formUnion(aSet.map { str in str.replacingOccurrences(of: "s", with: "5") })
  output.formUnion(oSet.map { str in str.replacingOccurrences(of: "s", with: "5") })
  output.formUnion(aoSet.map { str in str.replacingOccurrences(of: "s", with: "5") })
  return output
}

var mutations = pristine

if options.numbers {
  mutations.formUnion(appendNumbers(pristine))
}
if options.punctuation {
  mutations.formUnion(appendPunctuation(pristine))
}
if options.years {
  mutations.formUnion(appendYears(pristine))
}
if options.replacement {
  mutations.formUnion(replace(options.double ? mutations : pristine))
}

if options.full {
  print("--full not implemented yet")
}

if let outFile = options.ouputFile {
  let currentDir =
    URL(fileURLWithPath: outFile.first == "/" ? "/" : FileManager.default.currentDirectoryPath, isDirectory: true)
  let outURL = currentDir.appendingPathComponent(outFile)
  try ("\(mutations.joined(separator: "\n"))\n").write(to: outURL, atomically: true, encoding: .utf8)
} else {
  print(mutations.joined(separator: "\n"))
}
