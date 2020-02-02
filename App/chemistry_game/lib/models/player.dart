import 'package:chemistry_game/models/combination_card.dart';
import 'package:chemistry_game/models/compound_card.dart';
import 'package:chemistry_game/models/element_card.dart';
import 'package:chemistry_game/models/element_cards_data.dart';
import 'package:chemistry_game/models/reaction.dart';
import 'package:flutter/material.dart';
import 'package:quiver/collection.dart';

class Player{

  String name;
  String id;
  final points = 0;
  Multimap<String, ElementCard> elementCards = new Multimap<String, ElementCard>();
  List<CompoundCard> compoundCards = new List<CompoundCard>();
  ValueNotifier<List<Reaction>> buildMenuReactions = new ValueNotifier(List<Reaction>());

//  void setPlayerData(String name, String id) {
//    this.name = name;
//    this.id = id;
//    print("Player set PlayerData");
//  }

  /*Player(this.name, this.id) {
    setReactions();
    setElementCards();
  }*/
  Player(name, id, elementCards, compoundCards) {
    this.name = name;
    this.id = id;

    print("Player constructor");

    var cards = elementCards.toString().split("\n");

//    for(int i = 0; i < cards.length; i++) {
    //ElementCardsData elementCardsData = new ElementCardsData();
//    }

    for(int i = 0; i < cards.length - 1; i++) {
      print("Here");
      var data = cards[i].split(",");
      this.elementCards.add(data[1], ElementCard.fromString(cards[i]));//ElementCard(name: data[0], group: data[1], period: int.parse(data[2])));

      print(data[0] + data.toString());
    }



    print("Elements: " + cards.toString());
    var compoundCardsNames = compoundCards.toString().split("\n");

    for(int i = 0; i < compoundCardsNames.length - 1; i++)
    {
      this.compoundCards.add(CompoundCard.fromString(compoundCardsNames[i]));
    }

    print(compoundCardsNames);
  }

//  Player.setCards(var elementCards){
//    print(elementCards);
//  }
  /*Player(var elementCards){
    print("Player constructor");
  }*/

  /*{
    "H2" : ElementCard(name: "H2", group: "2A", period: 2),
    "02" : ElementCard(name: "02", group: "2A", period: 1),
    "A" : ElementCard(name: "A", group: "1A", period: 3),
    "B" : ElementCard(name: "B", group: "3A", period: 1),
    "C" : ElementCard(name: "C", group: "3A", period: 2),
    "D" : ElementCard(name: "D", group: "2A", period: 3),
    "F" : ElementCard(name: "F", group: "1A", period: 1),
    "E" : ElementCard(name: "E", group: "3A", period: 2)
  }*/

  /*void setElementCards() {
    elementCards.add("H2", ElementCard(name: "H2", group: "2A", period: 2));
    elementCards.add("H2", ElementCard(name: "H2", group: "2A", period: 2));
    elementCards.add("02", ElementCard(name: "02", group: "2A", period: 1));
    elementCards.add("A", ElementCard(name: "A", group: "1A", period: 3));
    elementCards.add("B", ElementCard(name: "B", group: "3A", period: 1));
    elementCards.add("C", ElementCard(name: "C", group: "3A", period: 2));
    elementCards.add("D", ElementCard(name: "D", group: "2A", period: 3));
    elementCards.add("F", ElementCard(name: "F", group: "1A", period: 1));
    elementCards.add("E", ElementCard(name: "E", group: "3A", period: 2));
  }*/

  void setCombinationCards() {
//    combinationCards.add(CombinationCard(name: "H2O"));
  }

  //TODO: add combinationCards and acceletorCard



  List<ElementCard> getElementCards() {
    return elementCards.values.toList();
  }

  void removeElementCard(String name, ElementCard elementCard) {
    elementCards.remove(name, elementCard);
    print(elementCards.keys);
  }

  void removeCompoundCard(CompoundCard compoundCard) {
    compoundCards.remove(compoundCard);
    print("Player c : " + compoundCards.length.toString());
  }

  void addElementCard(ElementCard elementCard) {
    elementCards.add(elementCard.name, elementCard);
  }

  void addCompoundCard(CompoundCard compoundCard) {
    compoundCards.add(compoundCard);
  }

  void deleteReaction(Reaction reaction) {
    buildMenuReactions.value.remove(reaction);
  }

  /*void setReactions() {
    Reaction reaction = new Reaction();
    reaction.addReactant(0, ElementCard(name: "H2", group: "2A", period: 1));
    reaction.addReactant(1, ElementCard(name: "O2", group: "2A", period: 1));
    reaction.addProduct(0, ElementCard(name: "H2O", group: "2A", period: 2));

    this.buildMenuReactions.value.add(reaction);
    this.buildMenuReactions.value.add(reaction);
  }*/
}