function [tt,sss,ttt,uuu]=l2_test(ran,opt)
load mnist_all

%2) pairwise distance
num=21;
tt=zeros(1,5);
sss=cell(1,10);
ttt=cell(1,10);
uuu=cell(1,10);

for kk=ran
eval(['knn=zeros(' num2str(num*2*length(ran))  ',size(test' num2str(kk) ',1));'])
cc=0;
for ll=ran
    if opt<=2
        eval(['load data_l2_' num2str(opt)  '/dis_' num2str(kk) '_' num2str(ll)])
    else
        eval(['load data_l2_' num2str(opt)  '/dis_' num2str(ll) '_' num2str(kk)])
    end
%tmp=tmp';

%eval(['load data_l2/dis_' num2str(ll) '_' num2str(kk)])
[aa,bb]=sort(tmp,1,'ascend');

eval(['knn(' num2str(num*cc+1) ':' num2str(num*cc+num) ',:)=aa(1:' num2str(num)  ',:);']);
%eval(['knn(' num2str(num*ll+1+num*length(ran)) ':' num2str(num*(ll+1)+num*(length(ran)+1)) ',:)=bb(1:' num2str(num)  ',:);']);
[kk,ll]
cc=cc+1;
end

cc=1;
for take=[1,5,11,15,21]
if(take<=num)
eval(['[tmp,bad]=acc(knn(1:end/2,:),kk+1,num,take);'])
tt(cc)=tt(cc)+length(bad);

if(take==1)
sss{kk+1}=bad;
ttt{kk+1}=floor((tmp(1:take,bad)-1)/num);
end

end
cc=cc+1;
end


end








%{
load mnist_all
ran=0:9;
bad=zeros(1,10);
for kk=ran
    eval(['knn=zeros(10,size(test' num2str(kk) ',1));'])    
    for ll=ran
        eval(['load data/test_2train' num2str(ll)])
        eval(['knn(ll+1,:)=dist_a{kk+1};']);
        [kk,ll]
    end
    [~,ind]=min(knn);
    bad(kk+1)=sum(ind~=kk+1);
end
bad
%}
