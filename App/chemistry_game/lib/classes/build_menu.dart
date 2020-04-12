import 'package:badges/badges.dart';
import 'package:chemistry_game/classes/utils.dart';
import 'package:chemistry_game/models/enums.dart';
import 'package:chemistry_game/models/reaction.dart';
import 'package:chemistry_game/models/room.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

final HttpsCallable callCompleteReaction =
CloudFunctions(region: "europe-west1").getHttpsCallable(
  functionName: 'completeReaction',
);

class BuildMenu {
  Reaction currReaction = new Reaction();

  ValueNotifier<BuildMenuShowingCardsType> buildMenuShowingCardsType =
      new ValueNotifier<BuildMenuShowingCardsType>(
          BuildMenuShowingCardsType.ElementCards);

  ValueNotifier<int> elementCardsInBuildMenuStartingIndex =
      new ValueNotifier<int>(0);
  ValueNotifier<int> compoundCardsInBuildMenuStartingIndex =
      new ValueNotifier<int>(0);
  ValueNotifier<bool> updatedUnseenCards = new ValueNotifier<bool>(false);

  int shownElementCards = 8;
  int shownCompoundCards = 8;

  bool completeReactionCalled = false;

  Widget createBuildMenuContent(double width, double height, Room room, String playerToken) {
    return Container(
        width: width,
        height: height,
        child: Column(
          children: <Widget>[
            drawReactionRow(width, height * 0.5, currReaction, room, playerToken),
            drawCardsArea(width, height * 0.5, room),
          ],
        ));
  }

  Widget drawCardTypeButtons(double width, double height, Room room) {
    return Container(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            height: height * 0.3,
            child: RaisedButton(
              child: Badge(
                position: BadgePosition.topRight(top: -12, right: -20),
                badgeContent: ValueListenableBuilder(
                  valueListenable: updatedUnseenCards,
                  builder: (BuildContext context, bool value, Widget widget) {
                    int unseenElementCards = 0;
                    room.player.getElementCards().forEach((e) {
                      if (!e.seen) unseenElementCards++;
                    });
                    return unseenElementCards <= 0
                        ? Container()
                        : Text(unseenElementCards.toString());
                  },
                  child: Text(""),
                ),
                child: Container(
                  child: Text("Elements"),
                ),
              ),
              onPressed: () {
                buildMenuShowingCardsType.value =
                    BuildMenuShowingCardsType.ElementCards;
                updatedUnseenCards.value = !updatedUnseenCards.value;
              },
            ),
          ),
          Container(
            height: height * 0.3,
            child: RaisedButton(
              child: Badge(
                  badgeContent: ValueListenableBuilder(
                      valueListenable: updatedUnseenCards,
                      builder:
                          (BuildContext context, bool value, Widget widget) {
                        int unseenCompoundCards = 0;
                        room.player.compoundCards.forEach((c) {
                          if (!c.seen) unseenCompoundCards++;
                        });
                        return unseenCompoundCards <= 0
                            ? Container()
                            : Text(unseenCompoundCards.toString());
                      },
                      child: Text("")),
                  position: BadgePosition.topRight(top: -12, right: -20),
                  child: Text("Compounds")),
              onPressed: () {
                buildMenuShowingCardsType.value =
                    BuildMenuShowingCardsType.CompoundCards;
                updatedUnseenCards.value = !updatedUnseenCards.value;
              },
            ),
          ),
          Container(
            height: height * 0.3,
            child: RaisedButton(
              child: Text("Accelerations"),
              onPressed: () {
                showToast("We work on Accelerations");
                //TODO: set to AccelerationCards
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget drawCardsArea(double width, double height, Room room) {
    return Container(
      width: width,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          drawCardTypeButtons(width * 0.2, height, room),
          drawCardsAvailable(width * 0.75, height, room),
        ],
      ),
    );
  }

  Widget drawCardsAvailable(double width, double height, Room room) {
    return Container(
      width: width,
      height: height,
      child: ValueListenableBuilder(
        builder: (BuildContext context, BuildMenuShowingCardsType value,
            Widget child) {
          List<Widget> cards = new List<Widget>();

          switch (buildMenuShowingCardsType.value) {
            case (BuildMenuShowingCardsType.ElementCards):
              return Row(
                children: <Widget>[
                  drawBuildMenuLeftArrow(
                      buildMenuShowingCardsType.value, width * 0.1),
                  ValueListenableBuilder(
                    valueListenable: elementCardsInBuildMenuStartingIndex,
                    builder: (BuildContext context, int value, Widget child) {
                      return ValueListenableBuilder(
                        valueListenable: currReaction.updated,
                        builder:
                            (BuildContext context, bool value2, Widget child) {
                          cards.clear();

                          room.player.getElementCards().forEach((card) => {
                                !card.usedInReaction
                                    ? cards.add(card.drawDraggableCard(
                                        width / shownElementCards, height))
                                    : null
                              });

                          int endIndex = ((elementCardsInBuildMenuStartingIndex
                                          .value +
                                      shownElementCards) <=
                                  cards.length
                              //room.player.getElementCards().length
                              ? elementCardsInBuildMenuStartingIndex.value +
                                  shownElementCards
                              : cards
                                  .length); //room.player.getElementCards().length);

                          var temp = room.player.getElementCards();

                          for (int i = value; i < endIndex; i++) {
                            room.player.setCardToSeen(
                                temp.elementAt(i).uuid, temp.elementAt(i).name);
                          }

                          return Row(
                            children: cards.length > 0
                                ? cards.sublist(
                                    elementCardsInBuildMenuStartingIndex.value,
                                    endIndex)
                                : cards,
                          );
                        },
                        child: Text(""),
                      );
                    },
                    child: Container(),
                  ),
                  drawBuildMenuRightArrow(
                      buildMenuShowingCardsType.value, width * 0.1, room),
                ],
              );

              break;
            case (BuildMenuShowingCardsType.CompoundCards):
              return Row(
                children: <Widget>[
                  drawBuildMenuLeftArrow(
                      buildMenuShowingCardsType.value, width * 0.1),
                  ValueListenableBuilder(
                    valueListenable: compoundCardsInBuildMenuStartingIndex,
                    builder: (BuildContext context, int value, Widget child) {
                      return ValueListenableBuilder(
                        valueListenable: currReaction.updated,
                        child: Text(""),
                        builder: (BuildContext context, bool value2, Widget child) {
                          cards.clear();

                          room.player.compoundCards.forEach((card) => {
                            !card.usedInReaction
                                ? cards.add(
                                card.drawDraggable(width / shownCompoundCards, height))
                                : null
                          });

                          int endIndex =
                          ((compoundCardsInBuildMenuStartingIndex.value +
                              shownCompoundCards) <=
                              cards.length
                              ? compoundCardsInBuildMenuStartingIndex.value +
                              shownCompoundCards
                              : cards.length);

                          var temp = room.player.compoundCards;

                          for (int i = value; i < endIndex; i++) {
                            room.player.setCardToSeen(
                                temp.elementAt(i).uuid, temp.elementAt(i).name);
                          }

                          return Row(
                            children: cards.length > 0
                                ? cards.sublist(
                                compoundCardsInBuildMenuStartingIndex.value,
                                endIndex)
                                : cards,
                          );
                        }
                      );
                    },
                    child: Container(),
                  ),
                  drawBuildMenuRightArrow(
                      buildMenuShowingCardsType.value, width * 0.1, room),
                ],
              );

              break;
            /*case (BuildMenuShowingCardsType.AccelerationCards):
            break;*/
            default:
              {
                print("Error, invalid type");
                return Container();
              }
          }
        },
        child: Container(
          width: width,
          height: height,
          color: Colors.red,
        ),
        valueListenable: buildMenuShowingCardsType,
      ),
    );
  }

  Widget drawBuildMenuLeftArrow(
      BuildMenuShowingCardsType buildMenuShowingCardsType, double width) {
    switch (buildMenuShowingCardsType) {
      case (BuildMenuShowingCardsType.ElementCards):
        return ValueListenableBuilder(
          valueListenable: elementCardsInBuildMenuStartingIndex,
          builder: (BuildContext context, int value, Widget child) {
            if (value - shownElementCards >= 0) {
              return Container(
                width: width,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: primaryGreen),
                  onPressed: () {
                    elementCardsInBuildMenuStartingIndex.value -=
                        shownElementCards;
                  },
                ),
              );
            } else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          },
          child: Container(),
        );
        break;
      case (BuildMenuShowingCardsType.CompoundCards):
        return ValueListenableBuilder(
          valueListenable: compoundCardsInBuildMenuStartingIndex,
          builder: (BuildContext context, int value, Widget child) {
            if (value - shownCompoundCards >= 0) {
              return Container(
                width: width,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: primaryGreen),
                  onPressed: () {
                    compoundCardsInBuildMenuStartingIndex.value -=
                        shownCompoundCards;
                  },
                ),
              );
            } else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          },
          child: Container(),
        );
        break;
      default:
        return Container();
    }
  }

  Widget drawBuildMenuRightArrow(
      BuildMenuShowingCardsType buildMenuShowingCardsType,
      double width,
      Room room) {
    switch (buildMenuShowingCardsType) {
      case (BuildMenuShowingCardsType.ElementCards):
        return ValueListenableBuilder(
          valueListenable: elementCardsInBuildMenuStartingIndex,
          builder: (BuildContext context, int value, Widget child) {
            int usedCards = 0;
            room.player.getElementCards().forEach((card) => {usedCards++});

            if (value + shownElementCards < usedCards) {
              return Container(
                width: width,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward, color: primaryGreen),
                  onPressed: () {
                    elementCardsInBuildMenuStartingIndex.value +=
                        shownElementCards;
                  },
                ),
              );
            } else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          },
          child: Container(),
        );
        break;
      case (BuildMenuShowingCardsType.CompoundCards):
        return ValueListenableBuilder(
          valueListenable: compoundCardsInBuildMenuStartingIndex,
          builder: (BuildContext context, int value, Widget child) {
            if (value + shownCompoundCards < room.player.compoundCards.length) {
              return Container(
                width: width,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward, color: primaryGreen),
                  onPressed: () {
                    compoundCardsInBuildMenuStartingIndex.value +=
                        shownCompoundCards;
                  },
                ),
              );
            } else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          },
          child: Container(),
        );
        break;
      default:
        return Container();
    }
  }

  Widget drawReactionRow(double width, double height, Reaction reaction, Room room, String playerToken) {
    return Container(
      width: width,
      height: height,
      child: Row(children: <Widget>[
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              drawCompleteButton(width, height, room, playerToken),
              reaction.draw(width * 0.8, height),
            ],
          ),
        ),
        drawDeleteButton(width * 0.1, height * 0.7, reaction)
      ]),
    );
  }

  Widget drawCompleteButton(double width, double height, Room room, String playerToken) {
    return ValueListenableBuilder(
      valueListenable: currReaction.exists,
      builder: (BuildContext context, bool value, Widget child) {
        if (value) {
          return child;
        } else {
          return Container(
            width: 0,
            height: 0,
          );
        }
      },
      child: IconButton(
        icon: Icon(Icons.check),
        color: Colors.green,
        onPressed: () async {
          if (room.player.finishedCards) {
            showToast("You have already finished");
            return;
          }

          if (completeReactionCalled) {
            showToast("Wait until the check is complete!");
            return;
          } else {
            completeReactionCalled = true;
          }

          List<Map<String, String>> leftCards = new List<Map<String, String>>();
          List<Map<String, String>> rightCards =
              new List<Map<String, String>>();

          currReaction.leftSideCards.values.forEach((card) {
            if (card != null) {
              leftCards.add({"name": card.name, "uuid": card.uuid});
            }
          });

          currReaction.rightSideCards.values.forEach((card) {
            if (card != null) {
              rightCards.add({"name": card.name, "uuid": card.uuid});
            }
          });

          var dataToSend = {
            "playerId": room.player.id,
            "playerToken": playerToken,
            "leftSideCards": leftCards,
            "rightSideCards": rightCards
          };
          showToast("wait...");
          await callCompleteReaction(dataToSend);
        },
      ),
    );
  }

  Widget drawDeleteButton(double width, double height, Reaction reaction) {
    return Container(
      width: width,
      height: height,
      child: ValueListenableBuilder(
        valueListenable: currReaction.exists,
        builder: (BuildContext context, bool value, Widget child) {
          if (value) {
            return child;
          } else {
            return Container(
              width: 0,
              height: 0,
            );
          }
        },
        child: IconButton(
          icon: Icon(Icons.delete_forever),
          color: Colors.red,
          onPressed: () {
            reaction.clear();
          },
        ),
      ),
    );
  }
}
