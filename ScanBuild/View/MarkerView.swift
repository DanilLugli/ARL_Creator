import SwiftUI
import Foundation

struct MarkerView: View {
    
    @ObservedObject var room: Room
    var building: Building
    var floor: Floor
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil
    @State private var selectedTab: Int = 0
    @State private var isNavigationActive = false
    @State private var isNavigationActive3 = false
    @State private var isDocumentPickerPresented2 = false
    var mapView = SCNViewContainer()
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("\(building.name) > \(floor.name) > \(room.name)")
                        .font(.system(size: 14))
                        .fontWeight(.heavy)
                    
                    
                    TabView(selection: $selectedTab) {
                        VStack {
                            if isDirectoryEmpty(url: room.roomURL.appendingPathComponent("MapUsdz")){
                                Text("Add Planimetry with + icon")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                    .padding()
                            } else {
                                VStack {
                                    ZStack {
                                        mapView
                                            .border(Color.white)
                                            .cornerRadius(10)
                                            .padding()
                                            .shadow(color: Color.gray, radius: 3)
                                        
                                        VStack {
                                            HStack {
                                                Spacer() // Push buttons to the right
                                                HStack {
                                                    Button("+") {
                                                        mapView.zoomIn()
                                                    }
                                                    .buttonStyle(.bordered)
                                                    .bold()
                                                    .background(Color.blue.opacity(0.4))
                                                    .cornerRadius(8)
                                                    
                                                    Button("-") {
                                                        mapView.zoomOut()
                                                    }
                                                    .buttonStyle(.bordered)
                                                    .bold()
                                                    .background(Color.blue.opacity(0.4))
                                                    .cornerRadius(8).padding()
                                                }
                                                .padding()
                                            }
                                            Spacer() // Push buttons to the top
                                        }
                                    }
                                }
                                .onAppear {
                                    mapView.loadRoomMaps(name: room.name, borders: true, usdzURL: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Room Planimetry", systemImage: "map.fill")
                        }
                        .tag(0)
                        
                        VStack {
                            if room.referenceMarkers.isEmpty {
                                VStack {
                                    Text("No Marker in \(room.name)")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.customBackground)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 50) {
                                        ForEach(filteredMarker, id: \.id) { marker in
                                            Button(action: {
                                                selectedMarker = marker
                                            }) {
                                                MarkerCardView(imageName: marker.image).padding()
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Marker", systemImage: "mappin.and.ellipse")
                        }
                        .tag(1)
                        
                        
                        VStack{
                            if floor.associationMatrix.isEmpty {
//                                VStack {
//                                    Text("Add Matrix with + icon")
//                                        .foregroundColor(.gray)
//                                        .font(.headline)
//                                        .padding()
//                                }
                                VStack{
                                    let isSelected = floor.isMatrixPresent(named: room.name, inFileAt: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                                    MatrixCardView(floor: floor.name, room: room.name, exist: isSelected, date: Date(), rowSize: 1)
                                
                                }
                                .padding()
                                
                            } else {
                                VStack{
                                    let isSelected = floor.isMatrixPresent(named: room.name, inFileAt: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                                    MatrixCardView(floor: room.name, room: room.name, exist: isSelected, date: Date(), rowSize: 1)
                                
                                }
                                .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Room Position", systemImage: "sum")
                        }
                        .tag(3)
                        
                        VStack {
                            Text("No connections available for \(room.name)")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("TransitionZone", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        }
                        .tag(2)
                    }
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ROOM")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if selectedTab == 0 {
                    HStack{
                        NavigationLink(destination: ScanningView(namedUrl: room), isActive: $isNavigationActive) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                        
                        Button(action: {
                            isDocumentPickerPresented2 = true
                        }) {
                            Label("Upload File", systemImage: "square.and.arrow.up.circle.fill").font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                        
                    }
                } else if selectedTab == 1 {
                    
                    Button(action: {
                        isDocumentPickerPresented2 = true
                    }) {
                        Label("Upload File", systemImage: "square.and.arrow.up.circle.fill").font(.system(size: 26))
                            .foregroundStyle(.white, .blue, .blue)
                    }
                    
                }else if selectedTab == 2 {
                    NavigationLink(destination: AddConnectionView(selectedBuilding: building)) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white, .blue, .blue)
                    }
                } else if selectedTab == 3 {
                    NavigationLink(destination: MatrixView(floor: floor, room: room), isActive: $isNavigationActive3) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white, .blue, .blue)
                            .onTapGesture {
                                self.isNavigationActive3 = true
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $isDocumentPickerPresented2) {
            DocumentPickerView { url in
                // Handle the selected file URL here
                print("Selected file URL: \(url)")
            }
        }
        .sheet(item: $selectedMarker) { marker in
            VStack {
                Text("Marker Details")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .foregroundColor(.white)
                selectedMarker?.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Text("Position Marker")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .foregroundColor(.white)
                mapView.border(Color.white).cornerRadius(10).padding().shadow(color: Color.gray, radius: 3)
                Spacer()
            }
            .padding()
            .background(Color.customBackground.ignoresSafeArea())
        }
    }
    
    var tabTitle: String {
        switch selectedTab {
        case 0: return "Planimentry"
        case 1: return "Markers"
        case 2: return "Room Position"
        case 3: return "Transition Zone"
        default: return ""
        }
    }
    
    var filteredMarker: [ReferenceMarker] {
        if searchText.isEmpty {
            return room.referenceMarkers
        } else {
            return room.referenceMarkers.filter { $0.imageName.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    func isDirectoryEmpty(url: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            return contents.isEmpty
        } catch {
            print("Error checking directory contents: \(error)")
            return true
        }
    }
    
    
    struct MarkerView_Previews: PreviewProvider {
        static var previews: some View {
            let buildingModel = BuildingModel.getInstance()
            let building = buildingModel.initTryData()
            let floor = building.floors.first!
            let room = floor.rooms.first!
            return MarkerView(room: room, building: building, floor: floor)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
