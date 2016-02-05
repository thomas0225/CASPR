function inWorkspace = wrench_closure_shang(dynamics,options)
    % Determine necessary variables for test
    A       =   -dynamics.L'; % Cable Jacobian
%     A
    n = size(A,1); m = size(A,2); % Size variables
    %% Evaluate Matrix Rank
    if(rank(A)==n)
        %% Determine a_t
        % Find a linearly independent set of vectors
        [~,R] = qr(A);
        indices = false(m,1);
        % Use QR to determine a set of linearly independent columns
        for i=1:n
            % find a vector that is non-zero for the first i vectors
            for j=1:m
                if((~indices(j))&&(sum(R(:,j)~=0)==i))
                    indices(j) = true;
                    break;
                end
            end
        end
        Ahat = A(:,indices); 
        a_t = -Ahat*ones(n,1); % A pose is WCW if the positive span contains this vector
        %% Detect the dot product sign
        % Take the dot product of each column with a_t
        DP = A'*a_t;
        % Check the sign of DP
        if((sum(DP<=0)==m) || (sum(DP>=0)==m))
            inWorkspace = 0;
        else
            % Determine all of the possible combinations
            index = DP>0;
            A_pos = A(:,index);
            A_neg = A(:,~index);
            l_pos = size(A_pos,2);
            l_neg = size(A_neg,2);
            flag = 0;
            if((l_pos>n-1)&&(l_neg>n-1))
                p = n;
            else
                p = min([l_neg,l_pos]);
                if(p==l_pos)
                    flag = 1;
                end
            end
            % For each combination evaluate the positivity condition
            for i=1:p
                a_l = flag*i + ~flag*(n+1-i);
                possible_pos = nchoosek(1:l_pos,a_l);
                for j=1:size(possible_pos,1)
                    % Map a combination into a set of vectors
                    pos_set = A_pos(:,possible_pos(j,:));
                    possible_neg = nchoosek(1:l_neg,n+1-a_l);
                    flag_2 = 0;
                    for k =1:size(possible_neg,1)
                        neg_set = A_neg(:,possible_neg(k,:));
                        A_i = [pos_set,neg_set];
                        A_p = pinv(A_i); N_i = null(A_i);
                        lambda = A_p*a_t; ratio_pos = [];
                        ratio_neg = []; 
                        for l = 1:n+1
                            if(abs(N_i(l))<=1e-6)
                                if(lambda(l) < 0)
                                    flag_2 = 1;
                                    break;
                                end
                            elseif(N_i(l) > 0)
                                ratio_pos = [ratio_pos,-lambda(l)/N_i(l)];
                            else
                                ratio_neg = [ratio_neg,-lambda(l)/N_i(l)];
                            end
                        end
                        if(flag_2)
                            break;
                        end
                        max_ratio_pos = max(ratio_pos); min_ratio_neg = min(ratio_neg); 
                        if(isempty(max_ratio_pos))
                            max_ratio_pos = -Inf;
                        elseif(isempty(min_ratio_neg))
                            min_ratio_neg = Inf;
                        end
                        if(max_ratio_pos <= min_ratio_neg)
                            inWorkspace = 1;
                            return;
                        end
                    end
                end
            end
            inWorkspace = 0;
        end
    else
        inWorkspace = 0;
    end
end
