import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Http "http";
import Debug "mo:base/Debug";

actor LinkShortener {
	type ShortLink = {
		owner: Principal;
		targetUrl: Text;
		title: Text;
		keywords: [Text];
		imagePreview: Text;
		clickCount: Nat;
		createdAt: Time.Time;
		updatedAt: Time.Time;
	};

	private stable var _links:[(Text, ShortLink)] = [];
	private var links = HashMap.HashMap<Text, ShortLink>(0, Text.equal, Text.hash);

	public shared(msg) func createLink(
		shortName: Text, 
		targetUrl: Text, 
		title: ?Text, 
		keywords: ?[Text], 
		imagePreview: ?Text
	) : async Bool {
		//Not allow anonymous
		assert not Principal.isAnonymous(msg.caller);
		
		if (links.get(shortName) != null) {
			return false; // Short name already exists
		};

		let newLink : ShortLink = {
			owner = msg.caller;
			targetUrl = targetUrl;
			title = Option.get(title, "ICTO Short Link");
			keywords = Option.get(keywords, []);
			imagePreview = Option.get(imagePreview, "default-image.jpg");
			clickCount = 0;
			createdAt = Time.now();
			updatedAt = Time.now();
		};

		links.put(shortName, newLink);
		true
	};

	public query func getLink(shortName: Text) : async ?ShortLink {
		links.get(shortName)
	};
	public func incrementClickCount(shortName: Text) : async () {
		switch (links.get(shortName)) {
		case (null) { };
		case (?link) {
			let updatedLink = {
			owner = link.owner;
			targetUrl = link.targetUrl;
			title = link.title;
			keywords = link.keywords;
			imagePreview = link.imagePreview;
			clickCount = link.clickCount + 1;
			createdAt = link.createdAt;
			updatedAt = Time.now();
			};
			links.put(shortName, updatedLink);
		};
		};
	};
	public shared(msg) func updateLink(
		shortName: Text, 
		targetUrl: ?Text, 
		title: ?Text, 
		keywords: ?[Text], 
		imagePreview: ?Text
	) : async Bool {
		switch (links.get(shortName)) {
			case (null) { false };
			case (?link) {
				if (link.owner != msg.caller) {
					return false; // Only owner can update
				};
				let updatedLink = {
				owner = link.owner;
				targetUrl = Option.get(targetUrl, link.targetUrl);
				title = Option.get(title, link.title);
				keywords = Option.get(keywords, link.keywords);
				imagePreview = Option.get(imagePreview, link.imagePreview);
				clickCount = link.clickCount;
				createdAt = link.createdAt;
				updatedAt = Time.now();
				};
				links.put(shortName, updatedLink);
				true
			};
		};
	};

	public shared(msg) func deleteLink(shortName: Text) : async Bool {
		switch (links.get(shortName)) {
		case (null) { false };
		case (?link) {
			if (link.owner != msg.caller) {
				return false; // Only owner can delete
			};
			ignore links.remove(shortName);
			true
		};
		};
	};

	public query func getUserLinks(user: Principal) : async [(Text, ShortLink)] {
		Iter.toArray(Iter.filter(links.entries(), func ((_, link) : (Text, ShortLink)) : Bool {
			link.owner == user
		}))
	};

	// Function to handle redirection
	public query func redirect(shortName: Text) : async ?Text {
		switch (links.get(shortName)) {
		case (null) { null };
		case (?link) {
			?link.targetUrl
		};
		};
	};

    system func preupgrade() {
        _links := Iter.toArray(links.entries());
    };

    system func postupgrade() {
        links := HashMap.fromIter(_links.vals(), 0, Text.equal, Text.hash);
        _links := [];
    };
}