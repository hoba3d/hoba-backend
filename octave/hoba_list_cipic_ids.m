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

