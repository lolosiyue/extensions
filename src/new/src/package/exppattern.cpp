#include "exppattern.h"
#include "engine.h"

ExpPattern::ExpPattern(const QString &exp)
{
    this->exp = exp;
	available = exp.startsWith("$");
	if(available) this->exp.remove("$");
}

bool ExpPattern::match(const Player *player, const Card *card) const
{
	if(available&&player&&!card->isAvailable(player))
		return false;
	if(exp.contains('#')){
		foreach(QString one_exp, exp.split('#'))
			if (matchOne(player, card, one_exp)) return true;
		return false;
	}
	return matchOne(player, card, exp);
}

// '|' means 'and', '#' means 'or'.
// the expression splited by '|' has 4 parts,
// 1st part means the card name, and ',' means more than one options.
// 2nd patt means the card suit, and ',' means more than one options.
// 3rd part means the card number, and ',' means more than one options,
// the number uses '~' to make a scale for valid expressions
// 4th part means the card place, and ',' means more than one options,
// "hand" stands for handcard and "equipped" stands for the cards in the placeequip
// if it is neigher "hand" nor "equipped", it stands for the pile the card is in.
bool ExpPattern::matchOne(const Player *player, const Card *card, QString one_exp) const
{
    bool checkpoint = false;
    QStringList factors = one_exp.split('|');
    foreach (QString or_name, factors[0].split(',')) {
        checkpoint = false;
        foreach (QString name, or_name.split('+')) {
            if (name == ".")
				checkpoint = true;
			else {
                bool positive = name.startsWith('^');
                if (positive) name = name.mid(1);
                if (card->getType()==name||card->toString()==name||"%"+card->objectName()==name||card->isKindOf(name.toLocal8Bit().data()))
                    checkpoint = !positive;
                else
                    checkpoint = positive;
            }
            if (!checkpoint) break;
        }
        if (checkpoint) break;
    }
	if(checkpoint){
		if (factors.length() < 2) return true;
	}else return false;

    checkpoint = false;
    foreach (QString suit, factors[1].split(',')) {
        if (suit == ".")
            checkpoint = true;
        else{
			bool positive = suit.startsWith('^');
			if (positive) suit = suit.mid(1);
			checkpoint = positive;
			if (card->getSuitString() == suit || card->getColorString() == suit)
				checkpoint = !positive;
		}
        if (checkpoint) break;
    }
	if(checkpoint){
		if (factors.length() < 3) return true;
	}else return false;

    checkpoint = false;
    foreach (QString number, factors[2].split(',')) {
        if (number == ".")
            checkpoint = true;
        else{
			bool positive = number.startsWith('^');
			if (positive) number = number.mid(1);
			checkpoint = positive;
			if(number.contains('~')){
				int from = 1, to = 13;
				QStringList params = number.split('~');
				if (params[0].size()>0) from = params[0].toInt();
				if (params[1].size()>0) to = params[1].toInt();
				if(card->getNumber() >= from && card->getNumber() <= to)
					checkpoint = !positive;
			}else{
				bool can;
				int n = number.toInt(&can);
				if(can){
					if(n==card->getNumber())
						checkpoint = !positive;
				}else if(number==card->getNumberString())
					checkpoint = !positive;
			}
		}
        if (checkpoint) break;
    }
	if(checkpoint){
		if (factors.length() < 4) return true;
	}else return false;

	checkpoint = factors[3] == "." || !player;
    if (!checkpoint){
        QList<int> ids;
        if (card->isVirtualCard()) ids = card->getSubcards();
        else ids << card->getEffectiveId();
		QStringList places = factors[3].split(',');
		foreach (int id, ids) {
			checkpoint = false;
			foreach (QString place, places) {
				bool positive = place.startsWith('^');
				if (positive) place = place.mid(1);
				checkpoint = positive;
				if (place == "equipped"){
					if(player->getEquipsId().contains(id))
						checkpoint = !positive;
				}else if (place == "hand"){
					if(player->handCards().contains(id))
						checkpoint = !positive;
				}else if (place.startsWith("%")) {
					place = place.mid(1);
					foreach(const Player *as, player->getAliveSiblings()){
						if (as->getPile(place).contains(id)) {
							checkpoint = !positive;
							break;
						}
					}
				} else{
					if(player->getPile(place).contains(id))
						checkpoint = !positive;
				}
				if (checkpoint)
					break;
			}
			if (!checkpoint)
				break;
        }
    }
    return checkpoint;
}