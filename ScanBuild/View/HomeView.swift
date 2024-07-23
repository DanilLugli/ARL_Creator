import SwiftUI
import Foundation

struct HomeView: View {
    
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    @State private var searchText = ""
    @State private var selectedBuilding: UUID = UUID()
    @State private var isNavigationActive = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                TextField("Search", text: $searchText)
                    .padding(7)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .padding(.top, 90)
                    .frame(maxWidth: .infinity)
                    .padding()
                
                
                if buildingsModel.getBuildings().isEmpty {
                    VStack {
                        Text("Add Building with + icon")
                            .foregroundColor(.gray)
                            .font(.headline)
                            .padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 50) {
                            ForEach(filteredBuildings, id: \.id) { building in
                                NavigationLink(destination: FloorView(building: building)) {
                                    DefaultCardView(name: building.name, date: building.lastUpdate).padding()
                                }
                            }
                        }
                    }.padding(.top, 30)
                }
            }
            .foregroundColor(.white)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.customBackground)
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("BUILDINGS")
                        .font(.system(size: 26))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink(destination: AddBuildingView()) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    }
                }
            }
        }
    }
    
    var filteredBuildings: [Building] {
        if searchText.isEmpty {
            return buildingsModel.getBuildings()
        } else {
            return buildingsModel.getBuildings().filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let _ = buildingModel.initTryData()
        
        return HomeView().environmentObject(buildingModel)
    }
}
