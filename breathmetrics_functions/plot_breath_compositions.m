function [fig] = plot_breath_compositions(bm,plot_type)
    
fig = figure; hold all;

n_breaths = length(bm.inhale_onsets);
    if strcmp(plot_type,'normalized')
        matsize = 1000;
        breath_mat = zeros(n_breaths,matsize);
        
        for b=1:n_breaths
            ind=1;
            this_breath_comp = zeros(1,matsize);
            this_inhale_length = bm.inhale_lengths(b);
            this_inhale_pause_length = bm.inhale_pause_lengths(b);
            if isnan(this_inhale_pause_length)
                this_inhale_pause_length=0;
            end
            this_exhale_length = bm.exhale_lengths(b);
            this_exhale_pause_length = bm.exhale_pause_lengths(b);
            if isnan(this_exhale_pause_length)
                this_exhale_pause_length=0;
            end
            total_pts = sum([this_inhale_length,this_inhale_pause_length,this_exhale_length,this_exhale_pause_length]);
            normed_inhale_length=round((this_inhale_length/total_pts)*matsize);
            normed_inhale_pause_length=round((this_inhale_pause_length/total_pts)*matsize);
            normed_exhale_length=round((this_exhale_length/total_pts)*matsize);
            normed_exhale_pause_length=round((this_exhale_pause_length/total_pts)*matsize);
            sum_check = sum([normed_inhale_length,normed_inhale_pause_length,normed_exhale_length,normed_exhale_pause_length]);
            % sometimes rounding is off by 1
            if sum_check>matsize
                normed_exhale_length=normed_exhale_length-1;
            elseif sum_check<matsize
                normed_exhale_length=normed_exhale_length+1;
            end
                
            this_breath_comp(1,ind:normed_inhale_length)=1;
            ind=normed_inhale_length;
            if normed_inhale_pause_length>0
                this_breath_comp(1,ind+1:ind+normed_inhale_pause_length)=2;
                ind=ind+normed_inhale_pause_length;
            end
            this_breath_comp(1,ind+1:ind+normed_exhale_length)=3;
            ind=ind+normed_exhale_length;
            if normed_exhale_pause_length>0
                this_breath_comp(1,ind+1:ind+normed_exhale_pause_length)=4;
            end
            breath_mat(b,:)=this_breath_comp;
        end
        
        % image
        imagesc(breath_mat)
        xlim([0.5,matsize+0.5])
        ylim([0.5,n_breaths+0.5])
        xlabel('Proportion of Breathing Period')
        ylabel('Breath Number')
        
        % colorbar
        cb = colorbar('Location','NorthOutside'); 
        caxis([1,4]) 
        ticklabels = {'Inhales';'Inhale Pauses';'Exhales';'Exhale Pauses'};
        set(cb,'XTick',[1,2,3,4],'XTickLabel',ticklabels)
        
    elseif strcmp(plot_type,'raw')
        matsize = 1000;
        max_breath_size = ceil(max(diff(bm.inhale_onsets))/bm.srate);
        breath_mat = zeros(n_breaths,matsize);
        for b=1:n_breaths
            this_breath_comp = ones(1,matsize)*4;
            %this_breath_comp(:)=nan;
            this_inhale_length = round((bm.inhale_lengths(b)/max_breath_size)*matsize);
            this_breath_comp(1,1:this_inhale_length)=0;
            ind=this_inhale_length+1;
            this_inhale_pause_length = round((bm.inhale_pause_lengths(b)/max_breath_size)*matsize);
            if isnan(this_inhale_pause_length)
                this_inhale_pause_length=0;
            end
            this_breath_comp(1,ind:ind+this_inhale_pause_length)=1;
            ind=ind+this_inhale_pause_length;
            this_exhale_length = round((bm.exhale_lengths(b)/max_breath_size)*matsize);
            this_breath_comp(1,ind:ind+this_exhale_length)=2;
            ind=ind+this_exhale_length;
            this_exhale_pause_length = round((bm.exhale_pause_lengths(b)/max_breath_size)*matsize);
            if isnan(this_exhale_pause_length)
                this_exhale_pause_length=0;
            end
            this_breath_comp(1,ind:ind+this_exhale_pause_length)=3;
            if length(this_breath_comp)>matsize
                this_breath_comp = this_breath_comp(1,1:matsize);
            end
            breath_mat(b,:)=this_breath_comp;
        end
        
        % image
        imagesc(breath_mat)
        xlim([0.5,matsize+0.5])
        ylim([0.5,n_breaths+0.5])
        tick_step = .5;
        xticklabels = 0:tick_step:max_breath_size;
        xticks = round(linspace(1,matsize,length(xticklabels)));
        set(gca,'XTick',xticks,'XTickLabel',xticklabels)
        xlabel('Time (sec)')
        ylabel('Breath Number')
        
        % colorbar
        cb = colorbar('Location','NorthOutside'); 
        caxis([0,4]) 
        ticklabels = {'Inhales';'Inhale Pauses';'Exhales';'Exhale Pauses';''};
        set(cb,'XTick',[0,1,2,3,4],'XTickLabel',ticklabels)
        
    elseif strcmp(plot_type,'line')
        % plots each breath as a function of how much time is spent in each
        % phase
        mycolors = parula(n_breaths);
        for b=1:n_breaths
            ind=1;
            this_inhale_length = bm.inhale_lengths(b);
            % there is always an inhale in a breath
            plotset = [ind,this_inhale_length];
            ind=ind+1;
            
            %there is sometimes an inhale pause
            this_inhale_pause_length = bm.inhale_pause_lengths(b);
            if ~isnan(this_inhale_pause_length)
                plotset(ind,:) = [2,this_inhale_pause_length];
                ind=ind+1;
            end
            
            this_exhale_length = bm.exhale_lengths(b);
            plotset(ind,:) = [3, this_exhale_length];
            ind=ind+1;
            this_exhale_pause_length = bm.exhale_pause_lengths(b);
            if ~isnan(this_exhale_pause_length)
                plotset(ind,:) = [4,this_exhale_pause_length];
            end
            plot(plotset(:,1),plotset(:,2),'color',mycolors(b,:))
        end
        inhale_sem = std(bm.inhale_lengths)/sqrt(length(bm.inhale_lengths));
        inhale_pause_sem = nanstd(bm.inhale_lengths)/sqrt(sum(~isnan(bm.inhale_pause_lengths)));
        exhale_sem = std(bm.exhale_lengths)/sqrt(length(bm.exhale_lengths));
        exhale_pause_sem = nanstd(bm.exhale_lengths)/sqrt(sum(~isnan(bm.exhale_pause_lengths)));
        all_means = [mean(bm.inhale_lengths),nanmean(bm.inhale_pause_lengths),mean(bm.exhale_lengths),nanmean(bm.exhale_pause_lengths)];
        all_sems = [inhale_sem,inhale_pause_sem,exhale_sem,exhale_pause_sem];
        t=errorbar([1,2,3,4],all_means,all_sems,'Color','k','LineStyle','none','LineWidth',3);
        xlim([0.5,4.5]);
        ticklabels = {'Inhale Lengths';'Inhale Pause Lengths';'Exhale Lengths';'Exhale Pause Lengths'};
        set(gca,'XTick',[1,2,3,4],'XTickLabel',ticklabels)
    end
end