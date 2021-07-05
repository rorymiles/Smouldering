% smouldering front detection

clear all
close all
clc

cd 'Processed movies'

%%%% UPDATE WITH THE EXPERIMENT/VIDEO FILENAMES
Filenames = [{'Unwashed Tea 001.mp4'}
    {'Unwashed Coffee 002.mp4'}
    {'Unwashed Tea 003.mp4'}
    {'Washed Tea 010.mp4'}
    {'Unwashed Coffee 011.mp4'}
    {'Washed Tea 012.mp4'}
    {'Washed Coffee 013.mp4'}
    {'Roasted tea 0014.mp4'}
    {'WashedTea004.mp4'}
    {'Washed Tea 007.mp4'}];

%%%%
line_pos = [{'high'}
    {'mid'}
    {'low'}];

%%%%
foil_length = 199; %mm

% train_start =[200 200 200 200 200 200 200 200];
% train_end = [1600 1490 1400 1400 1400 1400 1400];

Exp_ID = [1:1:length(Filenames)]'; %make a variable to correspond ot the input number

%%%% Display the info needed to select the input

table(Exp_ID, Filenames)
EXPERIMENT_IDs = str2num(input("Which experiment number to do you want to investigate?", 's'));

%this bit is to analyse all data by letting you hit return when asked
if isempty(EXPERIMENT_IDs)
    EXPERIMENT_IDs = 1:length(Filenames);
end


for i = 1:length(EXPERIMENT_IDs) % loop to specify more than 1 experiment to investigate
    
    %%%% Start the script for proper
    filename = cell2mat(Filenames(EXPERIMENT_IDs(i))); %this makes the cell into a string
    
    %%%% Do some things to make the variable names needed
    short_filename = filename(1:length(filename)-4);
    short_filename = short_filename(~isspace(short_filename));
    
    %%%% Read the video
    vid = VideoReader(filename);
    
    %%%% some variables to get things going
    duration = vid.Duration;
    frame_skip = duration/50;
    %vid.CurrentFrame = 1;
    k=1; % counter for the frame
    % measure_line_position = 650; %this is specified in the loop below
    % train_start = train_start(EXPERIMENT_ID);
    % train_end = train_end(EXPERIMENT_ID);
    
    %%%%% this secton only runs if the variable px2mm is not in the
    %%%%% TeaAndCoffee.mat file
    
    load ../TeaAndCoffee.mat %load the data file
    
    if  exist(short_filename, 'var') == 0 %if the variable does not exist show the image...
        
        %%%% allow adaptive input of the measurement line
        vid.CurrentTime = vid.Duration-1;
        input_frame = readFrame(vid);
        imshow(input_frame)
        
        % get the length of the piece of foil
        text(0,0,'Length of foil', 'verticalalignment', 'top', 'color', 'r')
        foil_pixels = drawline('StripeColor', 'r');
        px2mm = foil_length/(foil_pixels.Position(2,1)-foil_pixels.Position(1,1)); %mm/px
        
        % get the length of the train
        text(0,100,'Length of train', 'verticalalignment', 'top', 'color', 'g')
        train_size = drawline('StripeColor', 'g');
        train_start =  round(mean(train_size.Position(1,1)), 0);
        train_end =  round(mean(train_size.Position(2,1)), 0);
        
        %select measure line
        text(0,200,'Measure line', 'verticalalignment', 'top', 'color', 'y')
        ROI = drawline('StripeColor','y');
        measure_line_position = round(mean(ROI.Position(:,2)), 0);
        measure_line_positions = [measure_line_position-25 measure_line_position measure_line_position+25];
        disp(['Measure lines are at ' num2str(measure_line_positions)])
        close
        
    else %... otherwise load the variables
        
        px2mm = eval([short_filename '.px2mm']);
        measure_line_position = eval([short_filename '.measure_line_positions(2)']);
        measure_line_positions = eval([short_filename '.measure_line_positions']);
        train_start = eval([short_filename '.train_start']);
        train_end = eval([short_filename '.train_end']);
        
    end
    
    %%%% tell it to set the current time back ot 0 unless
    if strcmp(filename,'Unwashed Tea 001.mp4') ==1 % cos this video has a weird start
        vid.CurrentTime =8;
    else
        vid.CurrentTime =0;
    end
    
    hue_threshold = 0.25;
    j = 1; %counter to make sure that the front doesnt jump too far
    %k is the counter for the frame
    l = 1; %counter for subplotting every 10th frame.
    m = 1; %counter for measurement lines
    
    
    %%%% make some figures
    LE_fig = figure;
    frame_analysis_fig = figure;
    
    for measure_line_position = measure_line_positions
        
        while vid.CurrentTime < vid.Duration
            
            time_stamp(k) = vid.CurrentTime;
            
            frame = readFrame(vid);
            
            frame_hsv = rgb2hsv(frame);
            value = frame_hsv(:,:,3);
            hue = frame_hsv(:,:,1);
            sat = frame_hsv(:,:,2);
            
            measure_line = hue(measure_line_position,train_start:train_end);
            
            if strcmp(filename, 'Roasted tea 0014.mp4') == 1
                
                measure_line = frame(measure_line_position,train_start:train_end,3);%./frame(measure_line_position,train_start:train_end,3);
                edge = find(measure_line == min(measure_line))
                leading_edge(k) = max(edge)
                
                if rem(k/10,1)==0 %ervery 10th intenrval, plot the data to check
                    figure(frame_analysis_fig)
                    subplot(3,4,k/10)
                    hold on
                    image('CData', frame(:,:,1)./frame(:,:,3).*255, 'XData',[0 1920], 'YData', [0 -1080])
                    plot([0 1920], -[measure_line_position measure_line_position])
                    plot([train_start:1:train_end], measure_line*255);
                    plot([leading_edge(k) leading_edge(k)], [225 -1080])
                    l = l+1;
                end
                
                
            else
                
                if k == 1
                    high_hue = find(measure_line(1:round(0.5*(train_end-train_start)))>hue_threshold);
                    leading_edge(k) = max(high_hue)+train_start;
                else
                    high_hue = find(measure_line>hue_threshold);
                end
                
                if isempty(max(high_hue)) %just in case there isnt any max value
                    leading_edge(k) = train_start; %if no max value set it to the train start
                else
                    leading_edge(k) = max(high_hue)+train_start; %otherwise set it to the max pixel
                end
                
                hue_diff = diff(measure_line); %this is actualy not used at the moment
                
                if k>1 %this makes sure we dont jump too far ahead cos of spotting other maxima
                    while (leading_edge(k)-leading_edge(k-1))/leading_edge(k-1) >0.1
                        if isempty(max(high_hue(1:end-j))+train_start) ==1
                            leading_edge(k) =0;
                        else
                            leading_edge(k) = max(high_hue(1:end-j))+train_start; %if maxima are spotted,reduce the allowable max by j until it is within the tolerance
                        end
                        j=j+1
                    end
                    j=1;
                    if (leading_edge(k)-leading_edge(k-1))<0
                        leading_edge(k) = leading_edge(k-1);
                    end
                end
                
                
            end
            
            if rem(k/10,1)==0 %ervery 10th intenrval, plot the data to check
                figure(frame_analysis_fig)
                subplot(3,4,k/10)
                hold on
                image('CData', hue.*255, 'XData',[0 1920], 'YData', [0 -1080])
                plot([0 1920], -[measure_line_position measure_line_position])
                plot([train_start:1:train_end], measure_line*255);
                plot([leading_edge(k) leading_edge(k)], [225 -1080])
                l = l+1;
            end
            
            if vid.CurrentTime + frame_skip < vid.Duration %jump to the next time provided it exist
                vid.CurrentTime = vid.CurrentTime + frame_skip; %this is the next time
            else
                break
            end
            
            k=k+1;
            measure_line_position;
            
            disp(['Measurement position = ' num2str(measure_line_position)])
            disp(['Frame = ' num2str(k)])
            
        end
        
        leading_edge = leading_edge-train_start;
        
        leading_edge = leading_edge.*px2mm;
        
        velocity = smooth(diff(leading_edge), 'sgolay', 2, 21)./diff(time_stamp)';
        
        %save variables
        eval([short_filename '.leading_edge_' cell2mat(line_pos(m)) ' = (leading_edge)'])
        eval([short_filename '.velocity_' cell2mat(line_pos(m)) ' = (velocity)'])
        eval([short_filename '.time_stamp = (time_stamp)'])
        eval([short_filename '.measure_line_positions = (measure_line_positions)'])
        eval([short_filename '.px2mm = (px2mm)'])
        eval([short_filename '.train_start = (train_start)'])
        eval([short_filename '.train_end = (train_end)'])
        
        figure(LE_fig)%make a pretty plot
        yyaxis left
        hold on
        plot(time_stamp,leading_edge)
        yyaxis right
        hold on
        plot(time_stamp(1:end-1), velocity)
        
        
        % some house keeping to reset k
        k=1;
        
        %some kludge cos the video is weird
        if strcmp(filename, 'Unwashed Tea 001.mp4') ==1
            vid.CurrentTime =8;
        else
            vid.CurrentTime = 0;
        end
        m=m+1;
    end
    
    save('../TeaAndCoffee.mat', short_filename, '-append')
    
    clear leading_edge velocity time_stamp measure_line_positions measure_line_position px2mm train_end train_start
    
    close all
end
