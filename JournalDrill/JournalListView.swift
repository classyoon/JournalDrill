//
//  ContentView.swift
//  JournalDrill
//
//  Created by Conner Yoon on 8/21/22.
//

import SwiftUI

struct JournalEntry : Identifiable, Codable {// MODEL
    var id = UUID()
    var date = Date()
    var title = ""
    var note = ""
}

class JournalEntryList: ObservableObject { //View Model
    @Published var list : [JournalEntry] = []{
        didSet{
            saveEntries()
        }
    }
    let itemsKey: String = "entry_list"
    
    func saveEntries(){
        if let encodedData = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(encodedData, forKey: itemsKey)
        }
    }
    func getEntries() {
        guard
            let data = UserDefaults.standard.data(forKey: itemsKey),
            let savedItems = try? JSONDecoder().decode([JournalEntry].self, from: data)
        else { return }
        
        self.list = savedItems
    }
    func add(entry: JournalEntry){
        list.append(entry)
    }
    func delete(entry: JournalEntry){
        guard let index = list.firstIndex(where: {$0.id == entry.id}) else { return }
        list.remove(at: index)
    }
    func delete(at indexSet: IndexSet){
        list.remove(atOffsets: indexSet)
    }
    func move(from offsets: IndexSet, offset: Int){
        list.move(fromOffsets: offsets, toOffset: offset)
    }
    func update(entry: JournalEntry){
        guard let index = list.firstIndex(where: {$0.id == entry.id}) else { return }
        list[index] = entry
    }
    init(debug: Bool = false){
        if debug {
            self.list = dummyData
        }else{
            getEntries()
        }
    }

    private let dummyData = [
        JournalEntry(title: "one", note: "Hello this is the first note"),
        JournalEntry(title: "second", note: "My second note")
    ]
}

struct ListView: View {
    @StateObject var vm = JournalEntryList()//debug : true
    @State var isShowingSheet = false
    
    var body: some View {
        NavigationView{
            VStack{
                List{
                    ForEach(vm.list){ entry in
                        NavigationLink {
                            DetailView(entry: entry, completion: {entry in vm.update(entry: entry)})
                        } label: {
                            RowView(entry: entry)
                        }
                    }
                    .onDelete(perform: vm.delete)
                    .onMove(perform: vm.move)
                }
                .sheet(isPresented: $isShowingSheet) {
                    DetailView(entry: JournalEntry()) { entry in
                        vm.add(entry: entry)
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingSheet = true
                    } label: {
                        Text("Add")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            })
            .navigationTitle("List View")
        }
        
    }
}
struct RowView: View {
    let entry : JournalEntry
    var body: some View {
        VStack (alignment: .leading){
            Text("\(entry.title)")
                .font(.title)
            Text("\(entry.note)")
        }
    }
}
struct DetailView : View {
    @State var entry: JournalEntry
    var completion : (JournalEntry)->()
    
    @Environment(\.dismiss) var dismiss
    var body : some View {
        Form{
            TextField("enter title", text: $entry.title)
            TextField("enter note", text: $entry.note)
            Button {
                completion(entry)
                dismiss()
            } label: {
                Text("Save")
            }
        }
    }
}

struct JournalListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
        
    }
}
