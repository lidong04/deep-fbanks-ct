function [p_mid, r_mid, bias_mid] = pr_curve(labels, scores)
max_score = max(scores);
min_score = min(scores);

N = 100;
bias = min_score:(max_score - min_score) / (100 - 1):max_score;
for i = 1:N
    [precision(i), recall(i)] = pr_compute(labels, scores, bias(i));
    if i==N 
        precision(i) = 1;
    end
    sum(i) = precision(i) + recall(i);
end
s = sum' / 2;
%b = bias';
i = (1:N)';
tbl = table(s, i);
tbl_sorted = sortrows(tbl, {'s', 'i'}, {'descend', 'ascend'});
res = table2array(tbl_sorted);
max_pr = res(1,1);
idx_min = res(1,2);
j = 1;
while res(j,1) == max_pr
    idx_max = res(j,2);
    j = j + 1;
    if j > N
        break;
    end
end

if j > N
    j = N;
end
idx_mid = floor((idx_min+idx_max)/2);
p_mid = precision(idx_mid);
r_mid = recall(idx_mid);
bias_mid = bias(idx_mid);


%plot(recall, precision);
%plot(1:N, recall);




function [precision, recall] = pr_compute(labels, scores, bias)

tp = (labels>0) & (scores>bias);
fp = (labels<0) & (scores>bias);
fn = (labels>0) & (scores<=bias);
tn = (labels<0) & (scores<=bias);

precision = tp / (tp + fp);
recall = tp / (tp + fn);
