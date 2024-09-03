import Foundation
import SceneKit
import simd
import SwiftUI

class Floor: NamedURL, Encodable, Identifiable, ObservableObject, Equatable {
    
    private var _id = UUID()
    @Published private var _name: String
    private var _lastUpdate: Date
    private var _planimetry: SCNViewContainer?
    @Published var _associationMatrix: [String: RotoTraslationMatrix]
    @Published private var _rooms: [Room]
    @Published private var _sceneObjects: [SCNNode]?
    @Published private var _scene: SCNScene?
    @Published private var _sceneConfiguration: SCNScene?
    private var _floorURL: URL
    
    init(name: String, lastUpdate: Date, planimetry: SCNViewContainer?, associationMatrix: [String: RotoTraslationMatrix], rooms: [Room], sceneObjects: [SCNNode]?, scene: SCNScene?, sceneConfiguration: SCNScene?, floorURL: URL) {
        self._name = name
        self._lastUpdate = lastUpdate
        self._planimetry = planimetry
        self._associationMatrix = associationMatrix
        self._rooms = rooms
        self._sceneObjects = sceneObjects
        self._scene = scene
        self._sceneConfiguration = sceneConfiguration
        self._floorURL = floorURL
    }
    
    static func ==(lhs: Floor, rhs: Floor) -> Bool {
        return lhs.id == rhs.id // Compara gli ID, o qualsiasi altra proprietà unica
    }
    
    var id: UUID {
        return _id
    }
    
    var name: String {
        get {
            return _name
        }
        set {
            _name = newValue
            objectWillChange.send() // Forza la notifica di cambiamento
                
        }
    }
    
    var lastUpdate: Date {
        return _lastUpdate
    }
    
    var planimetry: SCNViewContainer {
        return _planimetry ?? SCNViewContainer()
    }
    
    var associationMatrix: [String: RotoTraslationMatrix] {
        get{
            return _associationMatrix
        }set{
            _associationMatrix = newValue
        }
    }
    
    var rooms: [Room] {
        get {
            return _rooms
        }
        set {
            _rooms = newValue
        }
    }
    
    func getRoom(_ room: Room) -> Room? {
        return rooms.first { $0.id == room.id}
    }
    
    var sceneObjects: [SCNNode]? {
        return _sceneObjects
    }
    
    var scene: SCNScene? {
        return _scene
    }
    
    var sceneConfiguration: SCNScene? {
        return _sceneConfiguration
    }
    
    var floorURL: URL {
        get {
            return _floorURL
        }
        set {
            _floorURL = newValue
        }
    }
    
    var url: URL {
        get {
            return floorURL
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case lastUpdate
        case rooms
        case associationMatrix
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_lastUpdate, forKey: .lastUpdate)
        try container.encode(_rooms, forKey: .rooms)
        try container.encode(_associationMatrix, forKey: .associationMatrix)
    }
    
    func getRoomByName(_ name: String) -> Room? {
        return rooms.first { $0.name == name }
    }
    
    func addRoom(room: Room) {
        _rooms.append(room)
        
        // Creare la directory della stanza all'interno di "<floor_name>_Rooms"
        let roomsDirectory = floorURL.appendingPathComponent(BuildingModel.FLOOR_ROOMS_FOLDER)
        let roomURL = roomsDirectory.appendingPathComponent(room.name)
        
        do {
            try FileManager.default.createDirectory(at: roomURL, withIntermediateDirectories: true, attributes: nil)
            room.roomURL = roomURL
            print("Folder created at: \(roomURL.path)")
            
            // Creare le cartelle all'interno della directory della stanza
            let subdirectories = ["JsonMaps", "JsonParametric", "Maps", "MapUsdz", "PlistMetadata", "ReferenceMarker", "TransitionZone"]
            
            for subdirectory in subdirectories {
                let subdirectoryURL = roomURL.appendingPathComponent(subdirectory)
                try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Subdirectory created at: \(subdirectoryURL.path)")
            }
            
        } catch {
            print("Error creating folder for room \(room.name): \(error)")
        }
    }

    func deleteRoom(room: Room) {
        // Rimuovi la room dall'array _rooms
        _rooms.removeAll { $0.id == room.id }
        
        // Ottieni l'URL della cartella della room da eliminare
        let roomURL = floorURL.appendingPathComponent(room.name)
        
        // Elimina la cartella della room dal file system
        do {
            if FileManager.default.fileExists(atPath: roomURL.path) {
                try FileManager.default.removeItem(at: roomURL)
                print("Room \(room.name) eliminata con successo da \(roomURL.path).")
            } else {
                print("La cartella della room \(room.name) non esiste.")
            }
        } catch {
            print("Errore durante l'eliminazione della room \(room.name): \(error)")
        }
    }
    
    func renameRoom(floor: Floor, room: Room, newName: String) throws {
        let fileManager = FileManager.default
        let oldRoomURL = room.roomURL
        let oldRoomName = room.name
        let newRoomURL = oldRoomURL.deletingLastPathComponent().appendingPathComponent(newName)

        // Verifica se esiste già una stanza con il nuovo nome
        guard !fileManager.fileExists(atPath: newRoomURL.path) else {
            throw NSError(domain: "com.example.ScanBuild", code: 3, userInfo: [NSLocalizedDescriptionKey: "Esiste già una stanza con il nome \(newName)"])
        }

        // Rinomina la cartella della stanza
        do {
            try fileManager.moveItem(at: oldRoomURL, to: newRoomURL)
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 4, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina della cartella della stanza: \(error.localizedDescription)"])
        }
        
        // Aggiorna l'oggetto room
        room.roomURL = newRoomURL
        room.name = newName
        
        // Aggiorna i file nelle sottocartelle della room rinominata
        do {
            try renameRoomFilesInDirectories(room: room, newRoomName: newName)
        } catch {
            print("Errore durante la rinomina dei file nelle sottocartelle della stanza: \(error.localizedDescription)")
        }
        
        // Aggiorna il contenuto del file JSON nella cartella del floor associato
        do {
            try updateRoomInFloorJSON(floor: floor, oldRoomName: oldRoomName, newRoomName: newName)
        } catch {
            print("Errore durante l'aggiornamento del contenuto del file JSON nel floor: \(error.localizedDescription)")
        }

        DispatchQueue.main.async {
            self.objectWillChange.send() // Notifica SwiftUI del cambiamento
        }

        
        // Ricarica i buildings dal file system per aggiornare i percorsi automaticamente
        BuildingModel.getInstance().buildings = []

        do {
            try BuildingModel.getInstance().loadBuildingsFromRoot()
        } catch {
            print("Errore durante il caricamento dei buildings: \(error)")
        }

    }
    
    func updateRoomInFloorJSON(floor: Floor, oldRoomName: String, newRoomName: String) throws {
        let fileManager = FileManager.default

        // Trova il file JSON del floor che contiene i nomi delle room
        let jsonFileURL = floor.floorURL.appendingPathComponent("\(floor.name).json")

        // Aggiorna il contenuto del file .json cambiando il nome della stanza
        do {
            let jsonData = try Data(contentsOf: jsonFileURL)
            var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

            // Verifica se il vecchio nome esiste nel file JSON
            guard let roomData = jsonDict?[oldRoomName] as? [String: Any] else {
                throw NSError(domain: "com.example.ScanBuild", code: 8, userInfo: [NSLocalizedDescriptionKey: "Il nome della stanza \(oldRoomName) non esiste nel file JSON del floor."])
            }

            // Aggiorna il nome della stanza nel file JSON
            jsonDict?.removeValue(forKey: oldRoomName)
            jsonDict?[newRoomName] = roomData

            // Scrivi il nuovo contenuto nel file JSON
            let updatedJsonData = try JSONSerialization.data(withJSONObject: jsonDict as Any, options: .prettyPrinted)
            try updatedJsonData.write(to: jsonFileURL)

            print("Contenuto del file JSON nel floor aggiornato con il nuovo nome della stanza \(newRoomName).")

        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 9, userInfo: [NSLocalizedDescriptionKey: "Errore durante l'aggiornamento del contenuto del file JSON nel floor: \(error.localizedDescription)"])
        }
    }
    
    func renameRoomFilesInDirectories(room: Room, newRoomName: String) throws {
        let fileManager = FileManager.default
        let directories = ["PlistMetadata", "MapUsdz", "JsonParametric", "Maps"]
        print("ENTRATO\n\n\n")

        let roomDirectoryURL = room.roomURL
        print("RoomDirectoryURL: \(roomDirectoryURL)\n")
        
        // Itera su ciascuna delle cartelle (PlistMetadata, MapUsdz, JsonParametric)
        for directory in directories {
            let directoryURL = roomDirectoryURL.appendingPathComponent(directory)
            print("directoryURL: \(directoryURL)\n")
            // Verifica se la directory esiste
            guard fileManager.fileExists(atPath: directoryURL.path) else {
                print("La directory \(directory) non esiste per la stanza \(room.name).")
                continue
            }

            // Ottieni tutti i file all'interno della directory
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

            // Itera su ciascun file per rinominarlo
            for oldFileURL in fileURLs {
                let oldFileName = oldFileURL.lastPathComponent
                let fileExtension = oldFileURL.pathExtension
                let newFileName = "\(newRoomName).\(fileExtension)"
                let newFileURL = oldFileURL.deletingLastPathComponent().appendingPathComponent(newFileName)

                do {
                    try fileManager.moveItem(at: oldFileURL, to: newFileURL)
                    print("File rinominato da \(oldFileName) a \(newFileName) nella directory \(directory).")
                } catch {
                    throw NSError(domain: "com.example.ScanBuild", code: 6, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina del file \(oldFileName) in \(directory): \(error.localizedDescription)"])
                }
            }
        }
    }
    
    func loadAssociationMatrixFromJSON(fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dictionary = jsonObject as? [String: [String: [[Double]]]] else {
                print("Error: Cannot convert JSON data to dictionary")
                return
            }
            
            for (key, value) in dictionary {
                guard let translationArray = value["translation"],
                      let r_YArray = value["R_Y"] else {
                    print("Error: Missing keys in dictionary")
                    continue
                }
                
                let translationMatrix = simd_float4x4(rows: translationArray.map { simd_float4($0.map { Float($0) }) })
                let r_YMatrix = simd_float4x4(rows: r_YArray.map { simd_float4($0.map { Float($0) }) })
                
                let rotoTranslationMatrix = RotoTraslationMatrix(name: key, translation: translationMatrix, r_Y: r_YMatrix)
                
                self._associationMatrix[key] = rotoTranslationMatrix
            }
            
            print("Association matrix loaded successfully from JSON file")
            
        } catch {
            print("Error loading JSON data: \(error)")
        }
    }
    
    func saveAssociationMatrixToJSON(fileURL: URL) {
        do {
            // Crea un dizionario per contenere i dati da salvare in JSON
            var dictionary: [String: [String: [[Double]]]] = [:]

            // Itera su tutte le chiavi e valori nell'association matrix
            for (key, value) in _associationMatrix {
                // Converti la matrice translation in un array di array di Double
                let translationArray: [[Double]] = (0..<4).map { index in
                    [Double(value.translation[index, 0]), Double(value.translation[index, 1]), Double(value.translation[index, 2]), Double(value.translation[index, 3])]
                }

                // Converti la matrice r_Y in un array di array di Double
                let r_YArray: [[Double]] = (0..<4).map { index in
                    [Double(value.r_Y[index, 0]), Double(value.r_Y[index, 1]), Double(value.r_Y[index, 2]), Double(value.r_Y[index, 3])]
                }

                // Crea un dizionario per contenere le matrici per questa stanza
                dictionary[key] = [
                    "translation": translationArray,
                    "R_Y": r_YArray
                ]
            }

            // Converti il dizionario in JSON
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)

            // Scrivi i dati JSON nel file
            try jsonData.write(to: fileURL)

            print("Association matrix saved successfully to JSON file")
            
        } catch {
            print("Error saving association matrix to JSON: \(error)")
        }
    }
    
    
    func updateAssociationMatrixInJSON(for roomName: String, fileURL: URL) {
        do {
            // Leggi il contenuto del file JSON
            var jsonData = try Data(contentsOf: fileURL)
            guard var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String: [[Double]]]] else {
                print("Error: Cannot convert JSON data to dictionary")
                return
            }

            // Assicurati che la chiave esista nel dizionario JSON
            guard let value = _associationMatrix[roomName] else {
                print("Room name \(roomName) not found in the association matrix")
                return
            }

            // Converti la matrice translation in un array di array di Double
            let translationArray = (0..<4).map { index in
                [Double(value.translation[0, index]), Double(value.translation[1, index]), Double(value.translation[2, index]), Double(value.translation[3, index])]
            }

            // Converti la matrice r_Y in un array di array di Double
            let r_YArray = (0..<4).map { index in
                [Double(value.r_Y[0, index]), Double(value.r_Y[1, index]), Double(value.r_Y[2, index]), Double(value.r_Y[3, index])]
            }

            // Aggiorna le matrici nel dizionario JSON per la chiave specificata
            jsonDict[roomName]?["translation"] = translationArray
            jsonDict[roomName]?["R_Y"] = r_YArray

            // Converti il dizionario aggiornato in JSON
            jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)

            // Scrivi i dati JSON nel file
            try jsonData.write(to: fileURL)

            print("Updated association matrix for room \(roomName) in JSON file")

        } catch {
            print("Error updating association matrix in JSON: \(error)")
        }
    }
    
    func isMatrixPresent(named matrixName: String, inFileAt url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let matricesDict = json as? [String: [String: [[Double]]]] else {
                print("Il formato del file JSON non è corretto.")
                return false
            }
            
            return matricesDict[matrixName] != nil
            
        } catch {
            print("Errore durante la lettura del file JSON: \(error)")
            return false
        }
    }
    
    private func simd_float4(_ array: [Float]) -> simd_float4 {
        return simd.simd_float4(array[0], array[1], array[2], array[3])
    }
    
    private func simd_float4x4(rows: [simd_float4]) -> simd_float4x4 {
        return simd_float4x4(rows: rows)
    }
}

extension Floor {
    
    func debugPrint() {
        print("=== Debug Info for Floor ===")
        print("ID: \(_id)")
        print("Name: \(_name)")
        print("Last Update: \(_lastUpdate)")
        print("Planimetry: \(_planimetry)")
        print("Association Matrix: \(_associationMatrix)")
        
        print("\nRooms: \(_rooms.count) room(s)")
        for room in _rooms {
            print("  Room ID: \(room.id), Name: \(room.name), Last Update: \(room.lastUpdate), URL: \(room.roomURL)")
        }
        
        if let sceneObjects = _sceneObjects {
            print("\nScene Objects: \(sceneObjects.count) object(s)")
            for (index, object) in sceneObjects.enumerated() {
                print("  Object \(index + 1): \(object)")
            }
        } else {
            print("\nScene Objects: None")
        }
        
        if let scene = _scene {
            print("\nScene: \(scene)")
        } else {
            print("\nScene: None")
        }
        
        if let sceneConfiguration = _sceneConfiguration {
            print("\nScene Configuration: \(sceneConfiguration)")
        } else {
            print("\nScene Configuration: None")
        }
        
        print("Floor URL: \(_floorURL)")
        print("============================")
    }
}
