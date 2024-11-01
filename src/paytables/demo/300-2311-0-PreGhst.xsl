<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario              = getScenario(jsonContext);
						var scenarioGameData      = getGameData(scenario);
						var convertedPrizeValues  = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames            = (prizeNamesDesc.substring(1)).split(',');

						////////////////////
						// Parse scenario //
						////////////////////

						const prizeSymbs = 'ABCDEFGH';

						var dataPrize = '';
						var prizeQty  = prizeSymbs.split('').map(function(item) {return 0;} );

						for (var turnIndex = 0; turnIndex < scenarioGameData.length; turnIndex++)
						{
							dataPrize = scenarioGameData[turnIndex][0];

							prizeQty[prizeSymbs.indexOf(dataPrize)]++;							
						}

						var winPrizes = prizeSymbs.split('').filter(function(item,index) {return prizeQty[index] == 3});

						var r = [];

						/////////////////////////
						// Currency formatting //
						/////////////////////////

						var bCurrSymbAtFront = false;
						var strCurrSymb      = '';
						var strDecSymb       = '';
						var strThouSymb      = '';

						function getCurrencyInfoFromTopPrize()
						{
							var topPrize               = convertedPrizeValues[0];
							var strPrizeAsDigits       = topPrize.replace(new RegExp('[^0-9]', 'g'), '');
							var iPosFirstDigit         = topPrize.indexOf(strPrizeAsDigits[0]);
							var iPosLastDigit          = topPrize.lastIndexOf(strPrizeAsDigits.substr(-1));
							bCurrSymbAtFront           = (iPosFirstDigit != 0);
							strCurrSymb 	           = (bCurrSymbAtFront) ? topPrize.substr(0,iPosFirstDigit) : topPrize.substr(iPosLastDigit+1);
							var strPrizeNoCurrency     = topPrize.replace(new RegExp(strCurrSymb, ''), '');
							var strPrizeNoDigitsOrCurr = strPrizeNoCurrency.replace(new RegExp('[0-9]', 'g'), '');
							strDecSymb                 = strPrizeNoDigitsOrCurr.substr(-1);
							strThouSymb                = (strPrizeNoDigitsOrCurr.length > 1) ? strPrizeNoDigitsOrCurr[0] : strThouSymb;
						}

						function getPrizeInCents(AA_strPrize)
						{
							return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
						}

						function getCentsInCurr(AA_iPrize)
						{
							var strValue = AA_iPrize.toString();

							strValue = (strValue.length < 3) ? ('00' + strValue).substr(-3) : strValue;
							strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
							strValue = (strValue.length > 6) ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
							strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

							return strValue;
						}

						getCurrencyInfoFromTopPrize();						

						///////////////////////
						// Output Game Parts //
						///////////////////////

						const cellHeight     = 25;
						const cellWidthStd   = 100;
						const cellWidthPrize = 150;
						const cellMargin     = 1;
						const cellTextY      = 15;
						const colourBlack    = '#000000';
						const colourOrange   = '#ffcc99';
						const colourRed      = '#ff9999';
						const colourWhite    = '#ffffff';
						const colourYellow   = '#ffff99';

						const colourPrizes = [colourRed, colourOrange];

						var boxColourStr  = '';
						var canvasIdStr   = '';
						var cellWidthVal  = 0;
						var elementStr    = '';
						var isPrizeCell   = false;
						var strCellText   = '';
						var textColourStr = '';

						function showBox(A_strCanvasId, A_strCanvasElement, A_iBoxWidth, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = A_iBoxWidth + 2 * cellMargin;
							var canvasHeight = cellHeight + 2 * cellMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + A_iBoxWidth.toString() + ', ' + cellHeight.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (A_iBoxWidth - 2).toString() + ', ' + (cellHeight - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_iBoxWidth / 2 + cellMargin).toString() + ', ' + cellTextY.toString() + ');');

							r.push('</script>');
						}

						///////////////
						// Main Game //
						///////////////

						const arrTitles  = ['titleTurn', 'titlePrize', 'titleRubies', 'titleWins'];
						const rubyPrizes = 'EDC';

						var dataRubies = 0;
						var rubyQty    = 0;
						var winIndex   = 0;

						prizeQty = prizeSymbs.split('').map(function(item) {return 0;} );

						r.push('<p>' + getTranslationByName("titleGameDetails", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tableheader">');

						for (var titleIndex = 0; titleIndex < arrTitles.length; titleIndex++)
						{
							isPrizeCell  = (titleIndex == 1 || titleIndex == 3);

							canvasIdStr  = 'cvsTitle' + titleIndex.toString();
							elementStr   = 'eleTitle' + titleIndex.toString();
							cellWidthVal = (isPrizeCell) ? cellWidthPrize : cellWidthStd;
							strCellText  = getTranslationByName(arrTitles[titleIndex], translations);

							r.push('<td align="center">');

							showBox(canvasIdStr, elementStr, cellWidthVal, colourBlack, colourWhite, strCellText);

							r.push('</td>');
						}

						r.push('</tr>');

						for (var turnIndex = 0; turnIndex < scenarioGameData.length; turnIndex++)
						{
							dataPrize  = scenarioGameData[turnIndex][0];
							prizeIndex = prizeSymbs.indexOf(dataPrize);
							winIndex   = winPrizes.indexOf(dataPrize);
							dataRubies = parseInt(scenarioGameData[turnIndex][1], 10);
							rubyQty    += dataRubies;

							prizeQty[prizeIndex]++;

							r.push('<tr class="tablebody">');

							for (var titleIndex = 0; titleIndex < arrTitles.length - 1; titleIndex++)
							{
								canvasIdStr   = 'cvsTurn' + turnIndex.toString() + '_' + titleIndex.toString();
								elementStr    = 'eleTurn' + turnIndex.toString() + '_' + titleIndex.toString();
								cellWidthVal  = (titleIndex == 1) ? cellWidthPrize : cellWidthStd;
								boxColourStr  = (titleIndex == 0) ? colourBlack : ((titleIndex == 1 && winIndex != -1) ? colourPrizes[winIndex] : ((titleIndex == 2 && dataRubies > 0) ? colourYellow : colourWhite));
								textColourStr = (titleIndex == 0) ? colourWhite : colourBlack;
								strCellText   = (titleIndex == 0) ? (turnIndex + 1).toString() : ((titleIndex == 1) ? convertedPrizeValues[getPrizeNameIndex(prizeNames, dataPrize)] : dataRubies.toString());

								r.push('<td align="center">');

								showBox(canvasIdStr, elementStr, cellWidthVal, boxColourStr, textColourStr, strCellText);

								r.push('</td>');
							}

							if (prizeQty[prizeIndex] == 3)
							{
								canvasIdStr  = 'cvsPrize' + turnIndex.toString();
								elementStr   = 'elePrize' + turnIndex.toString();
								boxColourStr = colourPrizes[winIndex];
								strCellText  = convertedPrizeValues[getPrizeNameIndex(prizeNames, dataPrize)];

								r.push('<td align="center">');

								showBox(canvasIdStr, elementStr, cellWidthPrize, boxColourStr, colourBlack, strCellText);

								r.push('</td>');
							}

							if (dataRubies > 0 && rubyQty >= 3)
							{
								for (var rubyPrize = Math.max(2, rubyQty - dataRubies); rubyPrize < rubyQty; rubyPrize++)
								{
									canvasIdStr  = 'cvsPrizeRuby' + turnIndex.toString() + '_' + rubyPrize.toString();
									elementStr   = 'elePrizeRuby' + turnIndex.toString() + '_' + rubyPrize.toString();
									dataPrize    = rubyPrizes[rubyPrize - 2];
									strCellText  = convertedPrizeValues[getPrizeNameIndex(prizeNames, dataPrize)];

									r.push('<td align="center">');

									showBox(canvasIdStr, elementStr, cellWidthPrize, colourYellow, colourBlack, strCellText);

									r.push('</td>');
								}
							}

							r.push('</tr>');
						}

						r.push('</table>');

						r.push('<p></p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						if(debugFlag)
						{
							//////////////////////////////////////
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getGameData(scenario)
					{
						return scenario.split(',');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
