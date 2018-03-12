function output = hoba_list_cipic_ids()
%LISTCIPICIDS Extract file names from cipic directory
    cd cipic;
    cipicFilenames = dir('*.mat');
    output = cell(1, size(cipicFilenames,1));
    for i = 1:size(cipicFilenames,1)
        [~, name, ~] = fileparts(cipicFilenames(i).name);
        output{1,i} = name(7:end);
    end
    cd ..;
    % Manual enumeration
    %     handles.cipicIDs = {'003', '008', '009', '010', '011', '012', '015', '017', '018', '019', ...
    %                         '020', '021', '027', '028', '033', '040', '044', '048', '050', '051', ...
    %                         '058', '059', '060', '061', '065', '119', '124', '126', '127', '131', ...
    %                         '133', '134', '135', '137', '147', '148', '152', '153', '154', '155', ...
    %                         '156', '158', '162', '163', '165', '134',
    %                         '165'};
end

function [ sortedCIPIC, sortedSumMismatch ] = hoba_hrtf_mismatch( F0, weightOne, weightTwo, weightThree)
%CALCULATEWEIGHTEDMISMATCH 
%   Calculates the mismatch between a given F0 and
%   all NotchFreq stored in the CIPIC database.
%   the weight values refer to contour 1 (the most external), contour 2
%   (in the middle) and contour 3 (the most internal). They must be
%   inserted as percent values expressed in the interval [0, 1].
%   They should sum at 1.

    if (isempty(F0) == 1)
      load(['./examples/IMG_3963.mat'], 'F0');
    end

    % Load data from CIPIC Database and calculate mismatch values for each
    % contour
    handles.cipicIDs = hoba_list_cipic_ids();
    %disp(handles.cipicIDs);
    handles.numCipicSubjects = size(handles.cipicIDs,2);

    mismatch = zeros(handles.numCipicSubjects,3);
    for idNum = 1:handles.numCipicSubjects
       cd cipic;
       load(['tracks' handles.cipicIDs{idNum} '.mat'], 'NotchFreq');
       cd ..;
       for contour = 1:1 	% for HOBA we have just C1
           % Some cipic subject do not have one (or more contours). We must
           % check for this and skip them.
           emptyContour = true;
           for phi = 1:17
               if ( NotchFreq(contour,phi) ~= 0 )
                   emptyContour = false;
                   break;
               end
           end
           if ( emptyContour )
               mismatch(idNum, contour) = -1;
               continue;
           end
           weight = 0;
           for phi = 1:17
               if ( NotchFreq(contour,phi) ~= 0 && F0(contour,phi) ~= 0 )
                   mismatch(idNum, contour) = mismatch(idNum, contour) + abs(NotchFreq(contour,phi) - F0(contour,phi))/NotchFreq(contour,phi);
                   weight = weight + 1;
               end
           end
           mismatch(idNum, contour) = mismatch(idNum, contour) / weight;
       end
    end
        
    % Calculate the global mismatch using all avaiable contours according
    % to the chosen weight.
    
    weights = [0 0 0];
    sumMismatch = zeros(handles.numCipicSubjects,2);
    sumMismatch(:,2) = 1:handles.numCipicSubjects;
    for idNum = 1:handles.numCipicSubjects
        % First of all, we calculate the number of avaiable mismatches
        % contours. We also remove the contours with required weight of
        % zero.
        if (weightOne == 0)
            mismatch(idNum, 1) = -1;
        end
        if (weightTwo == 0)
            mismatch(idNum, 2) = -1;
        end
        if (weightThree == 0)
            mismatch(idNum, 3) = -1;
        end
        avaiableContours = [];
        for contour = 1:3
            if ( mismatch(idNum, contour) ~= -1 )
                avaiableContours = [avaiableContours contour];
            end
        end
        % If there is only one contour, it get all the weight
        if ( length(avaiableContours) == 1 )
           weights = [0 0 0];
           weights(avaiableContours(1)) = 1; 
        end
        % If there are two contours, they get half the weight of the other
        % one (we do not care if the other one is zero).
        if ( length(avaiableContours) == 2 )
           if ( ismember(1,avaiableContours) && ismember(2,avaiableContours) )
               localWeightOne = weightOne+weightThree/2;
               localWeightTwo = weightTwo+weightThree/2;
               localWeightThree = 0;
           end
           if ( ismember(1,avaiableContours) && ismember(3,avaiableContours) )
               localWeightOne = weightOne+weightTwo/2;
               localWeightThree = weightThree+weightTwo/2;
               localWeightTwo = 0;
           end
           if ( ismember(2,avaiableContours) && ismember(3,avaiableContours) )
               localWeightTwo = weightTwo+weightOne/2;
               localWeightThree = weightThree+weightOne/2;
               localWeightOne = 0;
           end
           weights = [localWeightOne localWeightTwo localWeightThree];
        end
        % If there are three contours, just use them!
        if ( length(avaiableContours) == 3 )
            weights = [weightOne weightTwo weightThree];
        end  
        
        % Now we can calculate the weighted mean
        sumMismatch(idNum, 1) = mismatch(idNum, 1)*weights(1) + mismatch(idNum, 2)*weights(2) + mismatch(idNum, 3)*weights(3);
        
        % If sumMismatch is empty (-1), discard the value.
        if( sumMismatch(idNum, 1) == -1 )
            sumMismatch(idNum, 1) = 99;
        end
    end
   
    % If required, we can also print sumMismatch.
    % Here we are printing idNum, not cipidIDs, so:
    %
    % ID num | CIPIC ID    
    % 1 -> 003
    % 2 -> 008
    % 3 -> 009
    % 4 -> 010
    % 5 -> 011
    % 6 -> 012
    % 7 -> 015
    % 8 -> 017
    % 9 -> 018
    % 10 -> 019
    % 11 -> 020
    % 12 -> 021
    % 13 -> 027
    % 14 -> 028
    % 15 -> 033
    % 16 -> 040
    % 17 -> 044
    % 18 -> 048
    % 19 -> 050
    % 20 -> 051
    % 21 -> 058
    % 22 -> 059
    % 23 -> 060
    % 24 -> 061
    % 25 -> 065
    % 26 -> 119
    % 27 -> 124
    % 28 -> 126
    % 29 -> 127
    % 30 -> 131
    % 31 -> 133
    % 32 -> 134
    % 33 -> 135
    % 34 -> 137
    % 35 -> 147
    % 36 -> 148
    % 37 -> 152
    % 38 -> 153
    % 39 -> 154
    % 40 -> 155
    % 41 -> 156
    % 42 -> 158
    % 43 -> 162
    % 44 -> 163
    % 45 -> 165
    
    sumMismatch = sumMismatch(sumMismatch(:,1)<99,:); 

    sortedSumMismatch = sortrows(sumMismatch);
    
    %OUTPUT CIPIC ids
    sortedCIPIC = handles.cipicIDs(sortedSumMismatch(:,2));
end


% -----------------------------------------------------------------------------
% hoba server glue
% -----------------------------------------------------------------------------

% -- call function
args = [];
for i=1:length(argv())
	args = [args, str2num(argv(){i})];
end
[sortedCIPIC, sortedSumMismatch] = hoba_hrtf_mismatch(args, 1,0,0);

% -- convert return values to strings
ids = "[";
scores = "[";
for i=1:length(sortedSumMismatch)
    ids = [ids sprintf("%d,", sortedSumMismatch(:,2)(i))];
    scores = [scores sprintf("%f,", sortedSumMismatch(:,1)(i))];
end

% -- return as JSON
json = '{';
json = [ json '"ids":["' strjoin(sortedCIPIC,'","') '"],' ];
json = [ json '"matches":{' ];
json = [ json '"ids":' ids(1:end-1) '],' ];
json = [ json '"scores":' scores(1:end-1) ']}}' ];
disp(json);
