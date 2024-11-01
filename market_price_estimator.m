classdef price_estimator_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        scrollTip                  matlab.ui.control.TextArea
        TextArea_2                 matlab.ui.control.TextArea
        Image                      matlab.ui.control.Image
        Panel                      matlab.ui.container.Panel
        FarmProduceLabel           matlab.ui.control.Label
        ExpectedYieldKGLabel       matlab.ui.control.Label
        expectedYield              matlab.ui.control.Spinner
        cropselector               matlab.ui.control.DropDown
        PredictPriceButton         matlab.ui.control.Button
        Panel_2                    matlab.ui.container.Panel
        MarketLocationLabel        matlab.ui.control.Label
        PeriodOfsaleLabel          matlab.ui.control.Label
        DatePicker                 matlab.ui.control.DatePicker
        market                     matlab.ui.control.DropDown
        TextArea                   matlab.ui.control.TextArea
        Label_3                    matlab.ui.control.Label
        MarketPriceEstimatorLabel  matlab.ui.control.Label
        EditField                  matlab.ui.control.EditField
        UIAxes                     matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        crop 
        userYield
        intendmarket
        data
        monthOfSale
    end
    
    methods (Access = private)
        
        function state_data = getData(app,marketName,productName)

             state_data = app.data(app.data.product == productName & app.data.market == marketName,:);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: PredictPriceButton
        function PredictPriceButtonPushed(app, event)
                app.data = readtable('C:\Users\USER\Desktop\_\Matlab\matlab_competition\FEWS_NET_Staple_Food_Price_Data.xlsx');
                app.data.market = strcat(app.data.admin_1,{'  '},app.data.market); % Make market name easily accessible
                
                %check to convert period date data to datetime type
                if ~isdatetime(app.data.period_date)
                    app.data.period_date = datetime(app.data.period_date);
                end

                %Variable assignment
                app.crop = string(app.cropselector.Value);
                app.userYield = string(app.expectedYield.Value);
                app.intendmarket = string(app.market.Value);
            
            
                % Use user inputed value to get data
                state_data = getData(app, app.intendmarket, app.crop);

                % prices and date extraction
                dates = state_data.period_date;
                prices = state_data.value;

                
               
                
         
                %% Error handling
                % Check if state_data is not empty i.e i dont have such data
                if isempty(state_data)
                    uialert(app.UIFigure, 'No data found for the selected crop and market.', 'Data Error');
                    title(app.UIAxes, 'No Data to show');
                    return;
                end
                
                if isempty(app.DatePicker.Value)
                    uialert(app.UIFigure, 'Please select a valid date from October 2024 onward', 'Date Required');
                    return;
                end
                
                if app.expectedYield.Value <= 0
                    uialert(app.UIFigure, 'Invalid value for expected yield in KG', 'Expected Yield error');
                    return;
                end
                
                % check for stationality
                if adftest(prices) ==0
                    prices = log(prices);
                end

                %% model

                app.monthOfSale = floor(calmonths(between(dates(end), app.DatePicker.Value, "months")));
                if app.monthOfSale <= 0
                    app.monthOfSale = 10;
                end
                my_model = arima('Constant',0,'D',1,'Seasonality',12,'MALags',1,'ARLags',1);
                fittedmodel = estimate(my_model,prices);

                if app.monthOfSale <= 0
                    app.monthOfSale = 1; % Set to at least 1 if the result is invalid
                else
                    app.monthOfSale = floor(app.monthOfSale); % Ensure it's an integer
                end

     

                [forecastprice,~] = forecast(fittedmodel,app.monthOfSale,'Y0',prices);
                forecastprice = exp(forecastprice);
                moving_date = dates(end) + calmonths(1:app.monthOfSale);

                %% Display
                app.TextArea.Value = sprintf('Estimated price for %skg: %s(N) ',string(app.expectedYield.Value), string( ceil(forecastprice(end) * app.expectedYield.Value)));

                %% Plotting
                % Clear the previous plot
                cla(app.UIAxes); 
               
            
                % Plot the new data
                plot(app.UIAxes, state_data.period_date, state_data.value);
                hold(app.UIAxes, 'on')
                %set labels and title
                xlabel(app.UIAxes, 'Date');
                ylabel(app.UIAxes, 'Price in Naira(N)');
                title(app.UIAxes, sprintf('Price Prediction for %s in %s per KG', app.crop, app.intendmarket));

                predictDate = [dates(end); moving_date(:)];
                predictPrice = [exp(prices(end)); forecastprice(:)];
                
                %show plot of predicted month
                plot(app.UIAxes,predictDate,predictPrice,'r')
                hold(app.UIAxes, 'off')
                legend(app.UIAxes,'Recorded','Forecast');

                %% Scroll Tip
                if app.crop == 'Yams'
                    app.scrollTip.Value = {'Maximizing Profits:','Yams are a staple food and often in high demand around festive seasons. Storing yams to sell when prices peak can increase income. Direct sales to larger markets may reduce transportation costs and middleman fees.' ...
                            ,'','Financial Planning:','Yams require initial investment in seed yams (cuttings) and storage facilities. Consider building a yam barn for longer storage, as yams can spoil if left exposed.' ...
                            ,'','Crop Selection:','Yams do well in well-drained, fertile soils. Avoid waterlogged areas and choose disease-resistant varieties to ensure a high yield.' ...
                            ,'','Alternative Crop:','Cassava can be planted in the off-season to balance income and is less labor-intensive.' ...
                            ,'','Sustainability:','Rotate yam with legumes like beans to reduce soil nutrient depletion. Adding organic fertilizer or compost can improve soil fertility, helping the next yam crop thrive.'};
        
                elseif app.crop == 'Sorghum (White)'
                     app.scrollTip.Value = {'Maximizing Profits:','Brown sorghum has a demand in brewing, while white sorghum is popular in food and animal feed. Selling in bulk to food processors or breweries can help you secure better prices.' ...
                            ,'','Financial Planning:','Sorghum is hardy, needing fewer inputs. However, invest in pest control, as birds often target sorghum, especially during the harvest period.' ...
                            ,'','Crop Selection:','Sorghum is drought-tolerant and ideal for Nigeria,s drier areas, especially in northern regions.' ...
                            ,'','Alternative Crop:','Groundnuts or millet grow well in similar conditions, providing diversity in case of price drops for sorghum.' ...
                            ,'','Sustainability:','Practice crop rotation with legumes, which improve soil structure and add natural nitrogen, aiding future sorghum crops.'};
                
                elseif app.crop == 'Sorghum (Brown)'
                       app.scrollTip.Value = {'Maximizing Profits:','Brown sorghum has a demand in brewing, while white sorghum is popular in food and animal feed. Selling in bulk to food processors or breweries can help you secure better prices.' ...
                           ,'','Financial Planning:','Sorghum is hardy, needing fewer inputs. However, invest in pest control, as birds often target sorghum, especially during the harvest period.' ...
                           ,'','Crop Selection:','Sorghum is drought-tolerant and ideal for Nigeria,s drier areas, especially in northern regions.' ...
                           ,'','Alternative Crop:','Groundnuts or millet grow well in similar conditions, providing diversity in case of price drops for sorghum.' ...
                           ,'','Sustainability:','Practice crop rotation with legumes, which improve soil structure and add natural nitrogen, aiding future sorghum crops.'};

                elseif app.crop == 'Rice (Milled)'
                       app.scrollTip.Value = {'Maximizing Profits:','Rice is a high-demand crop, especially in urban areas. Selling directly to mills or wholesalers can increase profits, and broken rice has a steady market among lower-income consumers.' ...
                           ,'','Financial Planning:','Rice requires water, so investing in small-scale irrigation can stabilize production. Save funds for milling, as processed rice sells at higher prices.' ...
                           ,'','Crop Selection:','In regions with ample water or irrigation, rice varieties with high yield potential, like FARO 44 (SIPI), perform well.' ...
                           ,'','Alternative Crop:','Vegetables like tomatoes or peppers can be planted between rice seasons to generate extra income.' ...
                           ,'','Sustainability:','Rotate rice with legumes (e.g., soybeans) to improve soil fertility naturally. Water-saving techniques like drip irrigation can help reduce costs and conserve resources.'};

                elseif app.crop == 'Rice (5% Broken)'
                    app.scrollTip.Value = {'Maximizing Profits:','Rice is a high-demand crop, especially in urban areas. Selling directly to mills or wholesalers can increase profits, and broken rice has a steady market among lower-income consumers.' ...
                            ,'','Financial Planning:','Rice requires water, so investing in small-scale irrigation can stabilize production. Save funds for milling, as processed rice sells at higher prices.' ...
                            ,'','Crop Selection:','In regions with ample water or irrigation, rice varieties with high yield potential, like FARO 44 (SIPI), perform well.' ...
                            ,'','Alternative Crop:','Vegetables like tomatoes or peppers can be planted between rice seasons to generate extra income.' ...
                            ,'','Sustainability:','Rotate rice with legumes (e.g., soybeans) to improve soil fertility naturally. Water-saving techniques like drip irrigation can help reduce costs and conserve resources.'};

                elseif app.crop == 'Millet (Pearl)'
                    app.scrollTip.Value = {'Maximizing Profits:','Millet is resilient to drought and can be stored for long periods, which allows farmers to sell when prices rise. Millet is also valued for traditional foods and beverages, which have steady demand.' ...
                            ,'','Financial Planning:','Since millet is a hardy crop, it needs fewer inputs, but consider using organic fertilizer to boost growth and save money on synthetic fertilizers.' ...
                            ,'','Crop Selection:','Pearl millet is ideal for Nigeria,s semi-arid and drier regions, especially in the north.' ...
                            ,'','Alternative Crop:','Intercropping with cowpeas can increase soil fertility and yield better returns since cowpeas can be sold as a secondary crop.' ...
                            ,'','Sustainability:','Use organic mulch around millet to conserve soil moisture, especially in drier areas. This can help improve millet growth without requiring additional water.'};

                elseif app.crop == 'Maize Grain (Yellow)'
                    app.scrollTip.Value = {'Maximizing Profits:','Both white and yellow maize are staple foods in Nigeria and are also used for animal feed. Farmers can increase profits by timing their sales to when prices are high or by selling to large buyers, like feed mills or breweries.' ...
                            ,'','Financial Planning:','Maize is prone to weevils and other storage pests. Budget for proper storage bags or silos to avoid losses and keep grains marketable.' ...
                            ,'','Crop Selection:','Plant high-yield, early-maturing maize varieties to avoid damage from late-season droughts.' ...
                            ,'','Alternative Crop:','Intercropping with beans or cowpeas helps enrich the soil and reduces weed growth. These can also provide an additional source of income.' ...
                            ,'','Sustainability:','Rotating maize with legumes like soybeans helps fix nitrogen in the soil, enhancing fertility for the next crop season.'};

                elseif app.crop == 'Maize Grain (White)'
                    app.scrollTip.Value = {'Maximizing Profits:','Both white and yellow maize are staple foods in Nigeria and are also used for animal feed. Farmers can increase profits by timing their sales to when prices are high or by selling to large buyers, like feed mills or breweries.' ...
                            ,'','Financial Planning:','Maize is prone to weevils and other storage pests. Budget for proper storage bags or silos to avoid losses and keep grains marketable.' ...
                            ,'','Crop Selection:','Plant high-yield, early-maturing maize varieties to avoid damage from late-season droughts.' ...
                            ,'','Alternative Crop:','Intercropping with beans or cowpeas helps enrich the soil and reduces weed growth. These can also provide an additional source of income.' ...
                            ,'','Sustainability:','Rotating maize with legumes like soybeans helps fix nitrogen in the soil, enhancing fertility for the next crop season.'};
                else 
                    app.scrollTip.Value = {'Maximizing Profits:','Groundnuts have strong demand both for food and oil production. Selling groundnuts in bulk or directly to processors can yield better prices. You may also consider value addition, such as making groundnut oil or peanut butter, for additional income.' ...
                            ,'','Financial Planning:','Groundnuts don,t require heavy fertilization. However, put aside funds for pest control and invest in proper drying and storage. Storing groundnuts in cool, dry conditions can prevent mold and keep the quality high, fetching a better market price.' ...
                            ,'','Crop Selection:','Select drought-resistant varieties suited to the region,s rainfall, as these can endure dry spells.' ...
                            ,'','Alternative Crop:','Consider rotating with cowpeas or sesame, which can improve soil quality and reduce pests.' ...
                            ,'','Sustainability:','Use crop rotation with legumes like cowpeas to add nitrogen to the soil, improving groundnut yields in the following season.'};
                end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.9608 0.9294 0.7098];
            app.UIFigure.Position = [100 100 647 551];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Pointer = 'hand';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [39 299 553 209];

            % Create EditField
            app.EditField = uieditfield(app.UIFigure, 'text');
            app.EditField.BackgroundColor = [0.4667 0.6745 0.1882];
            app.EditField.Position = [1 522 647 30];

            % Create MarketPriceEstimatorLabel
            app.MarketPriceEstimatorLabel = uilabel(app.UIFigure);
            app.MarketPriceEstimatorLabel.FontName = 'ZapfDingbats';
            app.MarketPriceEstimatorLabel.FontSize = 20;
            app.MarketPriceEstimatorLabel.FontWeight = 'bold';
            app.MarketPriceEstimatorLabel.FontColor = [0.0902 0.1294 0.3804];
            app.MarketPriceEstimatorLabel.Position = [5 524 269 26];
            app.MarketPriceEstimatorLabel.Text = '        Market Price Estimator';

            % Create Label_3
            app.Label_3 = uilabel(app.UIFigure);
            app.Label_3.HorizontalAlignment = 'center';
            app.Label_3.FontName = 'TypoUpright BT';
            app.Label_3.FontSize = 15;
            app.Label_3.FontWeight = 'bold';
            app.Label_3.FontAngle = 'italic';
            app.Label_3.FontColor = [0.0902 0.1294 0.3804];
            app.Label_3.Position = [187 270 277 30];
            app.Label_3.Text = 'The  best  crop  price  prediction  app,  among  the  rest.......';

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.WordWrap = 'off';
            app.TextArea.FontName = 'ZapfDingbats';
            app.TextArea.FontSize = 14;
            app.TextArea.FontColor = [0.0392 0.0392 0.251];
            app.TextArea.BackgroundColor = [0.9608 0.9294 0.7098];
            app.TextArea.Placeholder = 'Click predict button to predict';
            app.TextArea.Position = [218 43 362 23];

            % Create Panel_2
            app.Panel_2 = uipanel(app.UIFigure);
            app.Panel_2.BorderWidth = 2;
            app.Panel_2.FontWeight = 'bold';
            app.Panel_2.FontSize = 10;
            app.Panel_2.Position = [192 110 136 149];

            % Create market
            app.market = uidropdown(app.Panel_2);
            app.market.Items = {'', 'Abia  Aba', 'Adamawa  Mubi', 'Borno  Biu', 'Borno  Maiduguri', 'Gombe  Gombe', 'Jigawa  Gujungu', 'Kaduna  Giwa', 'Kaduna  Saminaka', 'Kano  Kano, Dawanau', 'Katsina  Dandume', 'Kebbi  Gwandu, Dodoru', 'Lagos  Lagos, Mile 12', 'Oyo  Ibadan, Bodija', 'Yobe  Damaturu', 'Yobe  Potiskum', 'Zamfara  Kaura Namoda'};
            app.market.Tooltip = {'click to select intended market of sale'};
            app.market.FontName = 'Tw Cen MT';
            app.market.FontSize = 14;
            app.market.Placeholder = 'Select Market';
            app.market.Position = [9 93 118 30];
            app.market.Value = '';

            % Create DatePicker
            app.DatePicker = uidatepicker(app.Panel_2);
            app.DatePicker.Limits = [datetime([2024 10 1]) datetime([2045 12 31])];
            app.DatePicker.DisplayFormat = 'MM-yy';
            app.DatePicker.FontName = 'Tw Cen MT';
            app.DatePicker.FontSize = 14;
            app.DatePicker.Tooltip = {'click to select time of the year for the sale of product'};
            app.DatePicker.Placeholder = 'period of sale';
            app.DatePicker.Position = [9 16 118 30];

            % Create PeriodOfsaleLabel
            app.PeriodOfsaleLabel = uilabel(app.Panel_2);
            app.PeriodOfsaleLabel.FontName = 'Tw Cen MT';
            app.PeriodOfsaleLabel.FontWeight = 'bold';
            app.PeriodOfsaleLabel.FontColor = [0.502 0.502 0.502];
            app.PeriodOfsaleLabel.Position = [12 44 118 22];
            app.PeriodOfsaleLabel.Text = 'Period Of sale';

            % Create MarketLocationLabel
            app.MarketLocationLabel = uilabel(app.Panel_2);
            app.MarketLocationLabel.FontName = 'Tw Cen MT';
            app.MarketLocationLabel.FontWeight = 'bold';
            app.MarketLocationLabel.FontColor = [0.502 0.502 0.502];
            app.MarketLocationLabel.Position = [12 122 84 22];
            app.MarketLocationLabel.Text = 'Market Location';

            % Create PredictPriceButton
            app.PredictPriceButton = uibutton(app.UIFigure, 'push');
            app.PredictPriceButton.ButtonPushedFcn = createCallbackFcn(app, @PredictPriceButtonPushed, true);
            app.PredictPriceButton.IconAlignment = 'center';
            app.PredictPriceButton.BackgroundColor = [0.4667 0.6745 0.1882];
            app.PredictPriceButton.FontName = 'Tw Cen MT Condensed Extra Bold';
            app.PredictPriceButton.FontSize = 14;
            app.PredictPriceButton.FontWeight = 'bold';
            app.PredictPriceButton.FontColor = [1 1 1];
            app.PredictPriceButton.Tooltip = {'click after putting in the necessary values above, to predict price given inputed parameters'};
            app.PredictPriceButton.Position = [60 36 141 39];
            app.PredictPriceButton.Text = 'Predict Price';

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.BorderWidth = 2;
            app.Panel.Position = [50 110 130 149];

            % Create cropselector
            app.cropselector = uidropdown(app.Panel);
            app.cropselector.Items = {'', 'Groundnuts (Shelled)', 'Maize Grain (White)', 'Maize Grain (Yellow)', 'Millet (Pearl)', 'Rice (5% Broken)', 'Rice (Milled)', 'Sorghum (Brown)', 'Sorghum (White)', 'Yams'};
            app.cropselector.Tooltip = {'click to select farm produce '};
            app.cropselector.FontName = 'Tw Cen MT';
            app.cropselector.FontSize = 14;
            app.cropselector.Placeholder = 'Farm Produce';
            app.cropselector.Position = [12 93 109 30];
            app.cropselector.Value = '';

            % Create expectedYield
            app.expectedYield = uispinner(app.Panel);
            app.expectedYield.Tooltip = {'quantity of farm produce in Kg'};
            app.expectedYield.Position = [12 16 109 30];

            % Create ExpectedYieldKGLabel
            app.ExpectedYieldKGLabel = uilabel(app.Panel);
            app.ExpectedYieldKGLabel.FontName = 'Tw Cen MT';
            app.ExpectedYieldKGLabel.FontWeight = 'bold';
            app.ExpectedYieldKGLabel.FontColor = [0.502 0.502 0.502];
            app.ExpectedYieldKGLabel.Position = [14 44 118 22];
            app.ExpectedYieldKGLabel.Text = 'Expected Yield (KG)';

            % Create FarmProduceLabel
            app.FarmProduceLabel = uilabel(app.Panel);
            app.FarmProduceLabel.FontName = 'Tw Cen MT';
            app.FarmProduceLabel.FontWeight = 'bold';
            app.FarmProduceLabel.FontColor = [0.502 0.502 0.502];
            app.FarmProduceLabel.Position = [12 122 74 22];
            app.FarmProduceLabel.Text = 'Farm Produce';

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Position = [5 524 49 27];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'matlab_competition', '6d307c89-d414-49ae-97ae-78f38bf5f7a2-removebg-preview.png');

            % Create TextArea_2
            app.TextArea_2 = uitextarea(app.UIFigure);
            app.TextArea_2.HorizontalAlignment = 'center';
            app.TextArea_2.FontName = 'Tw Cen MT Condensed Extra Bold';
            app.TextArea_2.FontWeight = 'bold';
            app.TextArea_2.FontColor = [0.1255 0.1255 0.2784];
            app.TextArea_2.BackgroundColor = [0.902 0.8784 0.7373];
            app.TextArea_2.Position = [441 238 74 21];
            app.TextArea_2.Value = {'Tip Scroll'};

            % Create scrollTip
            app.scrollTip = uitextarea(app.UIFigure);
            app.scrollTip.FontColor = [0.1255 0.1255 0.2784];
            app.scrollTip.BackgroundColor = [0.9608 0.9294 0.7098];
            app.scrollTip.Position = [360 110 233 122];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = price_estimator_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end