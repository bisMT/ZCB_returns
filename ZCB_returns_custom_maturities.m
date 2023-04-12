% Get ARP from the RE
ARP  = getappdata(findall(0, 'tag', 'SCG_Reportfig'), 'ARP');
p = ARP.p;

% Get the Curve index from the Curve name
% CurveName should be the same as in the study file
CurveName = 'DE Gov';
i_Curve = UTL_GetCurveIndexFromName_T(p, CurveName);

% Parameters for currency hedging (naming should be consistent with the study file)
AssetCurrency = 'EUR';
CurrencyHedging = 'No';
CurrencyNumeraire = p.CurrencyNumeraire;
if strcmp(p.BaseCurrencyName, CurrencyNumeraire) || strcmp(CurrencyNumeraire, 'Local returns')
    iNumeraire = [];
else
    iNumeraire = find(strcmp(CurrencyNumeraire, p.CurrencyNames));
end

if isfield(p,'PBCurrencyReturnCalculation')
    CurrencyReturnCalculation = p.PBCurrencyReturnCalculation;
else
    CurrencyReturnCalculation = 'Geometric';
end


if ~strcmp(char(p.CurrencyNumeraire),'Local returns') && p.n_Currencies > 0
    doCurrencyHedging = true;
else
    doCurrencyHedging = false;
end

% Fixed Lambda
Lambda = str2double(p.Data.CurveSpecs(i_Curve).LambdaFix);

% Maturities [years]
Maturities = [0.25, 0.5, 1:10];

% Storage for results
HistRets_Loc = [];
HistCarry = [];
% Loop through maturities and calculate historical returns (assuming ZCB)
for m_tm1 = Maturities
    % Historical local returns
    m_t = m_tm1 - 1/p.Data.frequency;
    [y_t_hist, y_tm1_hist, m_t_hist, m_tm1_hist] = UTL_GetYieldsHist(ARP, p, m_t, m_tm1, Lambda, i_Curve);
    PriceBuy = (1 + y_tm1_hist/100).^(-m_tm1_hist);
    PriceSell = (1 + y_t_hist/100).^(-m_t_hist);
    HistRets_Loc_m = [nan; (PriceSell - PriceBuy) ./ PriceBuy];
    HistRets_Loc = [HistRets_Loc, HistRets_Loc_m]; %#ok<*AGROW>

    % Historical carry (annualized)
    y_t_hist_m_tm1 = SCG_GetYieldsHist_t(ARP, p, m_tm1, Lambda, i_Curve);
    PriceBuy_C = (1 + y_t_hist_m_tm1(2:end)/100) .^ (-m_tm1_hist);
    PriceSell_C = (1 + y_t_hist/100) .^ (-m_t_hist);
    HistCarry_m = [nan; (PriceSell_C - PriceBuy_C) ./ PriceBuy_C]*p.Data.frequency;
    HistCarry = [HistCarry, HistCarry_m];

    % Hedging
    if doCurrencyHedging

    end
end

% make a timetable
HistRets_Loc_TT = array2timetable(HistRets_Loc, 'RowTimes',  datetime(datestr(ARP.DateV)), 'VariableNames', string(Maturities));