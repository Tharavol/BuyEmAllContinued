-- Template for a new translation. Copy this file to localisation/<locale>.lua (for example itIT.lua), set the
-- locale code below, translate the strings, and add the file to localisation/index.xml.
--
-- Pull requests: https://github.com/Tharavol/BuyEmAllContinued/pulls
-- Without a pull request, open an issue with the translated file pasted in:
-- https://github.com/Tharavol/BuyEmAllContinued/issues
--
-- Any key left out falls back to the English text in enUS.lua.

if GetLocale() == "xxXX" then --change xxXX to the locale code, like itIT.
	BuyEmAll.L = {
	MAX 			= "Max",
	STACK 		= "Stack",
	CONFIRM 		= "Are you sure you want to buy\n %d × %s?", --%d is the number of items, %s is the item name. 'x' in the middle is the times sign (e.g. 201 x 'item')
	STACK_PURCH	= "Stack Purchase",
	STACK_SIZE 	= "Stack size",
	PARTIAL 		= "Partial stack",
	MAX_PURCH		= "Maximum purchase",
	FIT			= "You can fit",
	AFFORD		= "You can afford",
	AVAILABLE		= "Vendor has",
	PURCHASE_STOPPED	= "BuyEmAll: purchase stopped with %d of %d not bought.", --first %d is the amount not bought, second %d is the amount asked for.
}
end