//
//  DefaultCardView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 05/07/24.
//

import Foundation
import SwiftUI

struct DefaultCardView: View {
    var name: String
    var date: String
    var rowSize: Int
    
    init(name: String, date: String, rowSize: Int = 1) {
        self.name = name
        self.date = date
        self.rowSize = rowSize
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text(date)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 330/CGFloat(rowSize), height: 80)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding([.leading, .trailing], 10)
    }
}


struct DefaultCardView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultCardView(name: "1", date: "1-1-1999", rowSize: 3)
    }
}
