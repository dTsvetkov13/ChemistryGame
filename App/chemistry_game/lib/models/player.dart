import 'package:chemistry_game/models/compound_card.dart';
import 'package:chemistry_game/models/element_card.dart';
import 'package:quiver/collection.dart';

class Player{

  String name;
  String id;
  final points = 0;
  Multimap<String, ElementCard> elementCards = new Multimap<String, ElementCard>();
  List<CompoundCard> compoundCards = new List<CompoundCard>();
  bool finishedCards = false;

  Player(name, id, elementCards, compoundCards) {
    this.name = name;
    this.id = id;

    var cards = elementCards.toString().split("\n");

    for(int i = 0; i < cards.length - 1; i++) {
      var data = cards[i].split(",");
      this.elementCards.add(data[1], ElementCard.fromString(cards[i]));//ElementCard(name: data[0], group: data[1], period: int.parse(data[2])));
    }
    var compoundCardsNames = compoundCards.toString().split("\n");

    for(int i = 0; i < compoundCardsNames.length - 1; i++)
    {
      this.compoundCards.add(CompoundCard.fromString(compoundCardsNames[i]));
    }
  }

  List<ElementCard> getElementCards() {
    return elementCards.values.toList();
  }

  void removeElementCard(String name, ElementCard elementCard) {
    elementCards.remove(name, elementCard);
    print(elementCards.keys);
  }

  void removeCompoundCard(CompoundCard compoundCard) {
    compoundCards.remove(compoundCard);
  }

  void addElementCard(ElementCard elementCard) {
    elementCards.add(elementCard.name, elementCard);
  }

  void addCompoundCard(CompoundCard compoundCard) {
    compoundCards.add(compoundCard);
  }
}