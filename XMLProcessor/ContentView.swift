//
//  ContentView.swift
//  XMLProcessor
//
//  Created by Craig Hockenberry on 5/15/23.
//

import SwiftUI
import RNXML

struct Entry: Hashable {
	var title: String
	var date: Date
	var link: String
}

struct ContentView: View {
	
	@State private var entries: Array<Entry> = []
	
    var body: some View {
		NavigationStack {
			Form {
				ForEach(entries, id: \.self) { entry in
					NavigationLink {
						MarkdownView(entry: entry)
					} label: {
						HStack {
							Text(entry.title)
							Spacer()
							Text(entry.date, style: .date)
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
			}
			.formStyle(.grouped)
			.navigationTitle("Daring Fireball Atom Feed")
			.navigationBarTitleDisplayMode(.inline)
			.onAppear {
				Task {
					let url = URL(string: "https://daringfireball.net/feeds/main")!
					if let (xml, _) = try? await URLSession.shared.data(from: url) {
                        let document = try RNXMLParser().parse(data: xml)

                        let feed = try document["feed"]
                        self.entries = try feed[all: "entry"].compactMap { entry in
                            let title = try entry["title"].text
                            let published = try entry["published"].text

                            let links = entry[all: "link"].compactMap { entry in
                                if let relation = entry.attributes["rel"], relation == "related" || relation == "alternate",
                                   let href = entry.attributes["href"] {
                                    return (relation: relation, href: href)
                                } else {
                                    return nil
                                }
                            }

                            let link = links.first(where: { $0.relation == "related"} )?.href ?? links.first(where: { $0.relation == "alternate"} )?.href ?? "https://daringfireball.net"

                            if let date = ISO8601DateFormatter().date(from: published) {
                                return Entry(title: title, date: date, link: link)
                            }

                            return nil
                        }
					}
				}
			}
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
