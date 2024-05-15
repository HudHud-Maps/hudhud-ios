//
//  DictionaryView.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import POIService
import SwiftUI

// MARK: - DictionaryView

struct DictionaryView: View {

	let dictionary: [String: AnyHashable]

	var body: some View {
		List {
			ForEach(Array(self.dictionary.keys.sorted()), id: \.self) { key in
				let value = self.dictionary[key]! // swiftlint:disable:this force_unwrapping

				HStack(alignment: .top) {
					Text(key)
						.frame(width: 110, alignment: .trailing)
						.bold()

					switch value {
					case let intValue as Int:
						Text("\(intValue)")
					case let text as String:
						Text(text)
					case let array as [String]:
						Text(array.joined(separator: "\n"))
					case let convertable as DictionaryConvertable:
						NavigationLink(destination: {
							DictionaryView(dictionary: convertable.dictionary())
								.navigationTitle(key)
						}, label: {
							Text(convertable.description)
						})
					default:
						Text("\(value.description)")
					}
				}
				.alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
					return -viewDimensions.width
				}
			}
		}
		.listStyle(.plain)
	}
}

// MARK: - DictionaryConvertable

protocol DictionaryConvertable: CustomStringConvertible {
	func dictionary() -> [String: AnyHashable]
}

extension DictionaryConvertable {

	func dictionary() -> [String: AnyHashable] {
		var dict = [String: AnyHashable]()
		let mirror = Mirror(reflecting: self)
		for child in mirror.children {
			guard let key = child.label else { continue }

			let childMirror = Mirror(reflecting: child.value)
			switch childMirror.displayStyle {
			case .struct, .class:
				if let childDict = (child.value as? DictionaryConvertable)?.dictionary() {
					dict[key] = childDict
				}
			case .collection:
				if let childArray = (child.value as? [DictionaryConvertable])?.compactMap({ $0.dictionary() }) {
					dict[key] = childArray
				}
			case .set:
				if let childArray = (child.value as? Set<AnyHashable>)?.compactMap({ ($0 as? DictionaryConvertable)?.dictionary() }) {
					dict[key] = childArray
				}
			default:
				if let child = child.value as? CustomStringConvertible {
					dict[key] = child.description
				}

				dict[key] = child.value as? AnyHashable
			}
		}

		return dict
	}
}

extension Address: DictionaryConvertable {}
extension POIElement: DictionaryConvertable {}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
	let poi: POIElement = .starbucksKualaLumpur
	let dictionary = poi.dictionary()
	return DictionaryView(dictionary: dictionary)
}
