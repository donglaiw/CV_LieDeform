
digit=6;
load mnist_all	

%0. preprocessing 
[numtrain,lendigit]=eval(['size(train' num2str(digit) ')']);
sq=sqrt(lendigit);

imgs=zeros(numtrain,lendigit);
ntrain=zeros(numtrain,lendigit);
G = fspecial('gaussian',[3 3],2);
bad=[];
for i=1:numtrain
tmp=eval(['double(reshape(train' num2str(digit) '(i,:),sq,sq))/255;']);
%biggest connected component
pp=bwconncomp(tmp);
%throw it away since many bad situations that can't be told apart
if pp.NumObjects>1
%ind=cellfun(@length,pp.PixelIdxList);

%{
[aa,bb]=max(ind);
ind=[1:bb-1,bb+1:pp.NumObjects];
for j=ind
tmp(pp.PixelIdxList{j})=0;
end
%}
%{
for j=find(ind<15)
tmp(pp.PixelIdxList{j})=0;
end
%}
bad=[bad,i];
end



if pp.NumObjects==1
%feature
%blur
%tmp2 = imfilter(tmp,G,'same');
tmp2 = tmp;
imgs(i,:)=f_bb2(tmp2,sq)';
ntrain(i,:)=tmp2(:);
end

end

imgs(bad,:)=[];
ntrain(bad,:)=[];
numtrain=numtrain-length(bad);


%save scale0 ntrain imgs l2norm
%see2(1:200,'simgs','scale0')


%1) Reduction I: Local Perturbation

%guruantee the number in the first round to preserve variablity instead of using one same threshold
r_thres=0.05;
lc=1000;
wrong=0;
while lc<300 || lc>500
    if lc>500
            r_thres=r_thres+0.01;
        else
                r_thres=r_thres-0.01;
            end
glabel=2:numtrain;
cc=[1];
cindex={};
while(length(glabel)>0)
    % imadjust...
    ratio=IDM8(imgs(glabel,:)',imgs(cc(end),:)')';
    %ratio=ww2./l2norm(glabel);
    %ratio=ww2./(sum(imgs(cc(end),:))+sum(imgs(glabel,:),2));
    [aa,bb]=max(ratio);
    if(aa<=r_thres)
        %done
        cindex{length(cc)}=glabel;
        glabel=[];
    else
        cindex{length(cc)}=glabel(find(ratio<=r_thres));
        cc=[cc,glabel(bb)];
        glabel([bb;find(ratio<=r_thres)])=[];
    end
    [length(cc),length(glabel)]
end

if length(cc)>length(cindex)
    cindex{length(cc)}=[];
end

lc=length(cc)

if r_thres<0.02
disp(['sth. wrong.....................'])
wrong=1;
break;
end
end




if wrong==0
%save scale1 cc cindex
%seep_bk(cc,cindex,'imgs','scale0')
%seep(cc,cindex,imgs)
%see2(1:length(cc),imgs(cc,:))



%2) Reduction II: Affine + peturbation
addpath('brute/')
rot_set=-60:10:60;
shear_set=-0.5:0.5:0.5;
lr=length(rot_set);
ls=length(shear_set);
ll=lr*ls*ls;
trans_ind=[reshape(ones(ls*ls,1)*rot_set,1,ll);repmat(reshape(ones(ls,1)*shear_set,1,ls*ls),1,lr);repmat(shear_set,1,ls*lr)];
trans_s=trans_ind(1,:)+trans_ind(2,:)+4*trans_ind(3,:);
%for later 2d conversion
newimgs=zeros(length(cc),lr*ls*ls,lendigit);

mid=(ll+1)/2;
nomid=setdiff(1:ll,mid);
for i=1:lc
%all angles
    tmp=reshape(ntrain(cc(i),:),sq,sq);
    for j=1:lr
        tmpp=imrotate(tmp,rot_set(j),'crop');
        for k=1:ls
            for kk=1:ls
                mat=[1,shear_set(k),0;shear_set(kk),1+shear_set(k)*shear_set(kk),0;0,0,1];
                tform = maketform('affine',mat);
                tmp2 = imtransform(tmpp,tform);  
                newimgs(i,(j-1)*ls*ls+(k-1)*ls+kk,:)=f_bb2(tmp2,sq)';
            end
        end
    end
end

%see2(1:ll,squeeze(newimgs(1,:,:)))

glabel=2:lc;
cc2=[1];
cindex2={};
tindex2={};
while(length(glabel)>0)
%[trans,ind]=Align2_bk(imgs(cc2(end),:),simgs(glabel,:),l2norm(glabel),sq,r_thres); 
    [trans,ind]=Align3(squeeze(newimgs(cc2(end),mid,:)),newimgs(glabel,nomid,:),r_thres);
    
    %quick hack... measure dis in all combo but suppose matched to the mid pose
    %too costly....
    %[trans,ind]=Align3(squeeze(newimgs(cc2(end),:,:)),newimgs(glabel,nomid,:),r_thres,2);


    cindex2{length(cc2)}=glabel(ind);
    tindex2{length(cc2)}=nomid(trans);
    glabel(ind)=[];
     cc2=[cc2,glabel(1)];
     glabel(1)=[];
     [length(cc2),length(glabel)]
end
if length(cc2)>length(cindex2)
cindex2{length(cc2)}=[];
tindex2{length(cc2)}=[];
end
lc2=length(cc2)
%IDM8(squeeze(newimgs(cc2(2),mid,:)),squeeze(newimgs(cc2(4),mid,:)))
%seep2(tindex2,cindex2,cc2,newimgs,trans_ind)
%seet2(newimgs(cc2,:,:),ones(1,lc2)*mid)

%{
landmark=cc(cc2);
lan_tran=cell(1,lc2);
lan_pt=cindex(cc2);
for i=1:length(cindex2)
    lens=[0,cumsum(cellfun(@length,cindex(cindex2{i})))];
    lan_tran{i}=[mid*ones(1,length(cindex{cc2(i)})),tindex2{i},ones(1,lens(end))];
    for j=1:length(lens)-1
        lan_tran{i}(end-lens(j+1):end-lens(j))=tindex2{i}(j); 
    end
    lan_pt{i}=[lan_pt{i},cc(cindex2{i}),cindex{cindex2{i}}];     
end

%}

%save b_con3.mat
%3.2) congeal NN
[g_ind,g_trans]=Congeal3(newimgs(cc2,:,:),r_thres*1.5,20,r_thres*2);
%4) merge cc/cc2/ccindex/ccindex2
lg=length(g_ind);
strain=cell(1,lg);
dis=cell(1,lg);
land1=cell(1,lg);
land2=cell(1,lg);
land3=cell(1,lg);
aligned=zeros(lg,lendigit);
for ii=1:lg
    lan=g_ind{ii};
    tran=g_trans{ii};
    l_lan=length(lan);
    l_lan2= length([cindex2{lan}]);
    %l_lan3= sum(cellfun(@length,cindex(cc2(lan))))+sum(cellfun(@length,cindex([cindex2{lan}])));
    l_lan3=length([cindex{cc2(lan)}])+length([cindex{[cindex2{lan}]}]);
    strain{ii}=zeros(l_lan+l_lan2+l_lan3,lendigit);

    land1{ii}=1:l_lan;
    land2{ii}=cell(1,l_lan);
    land3{ii}=cell(1,l_lan+l_lan2);

    %l_pt=sum(cellfun(@length,lan_pt{lan}));

    %landmarks
    curr3=l_lan+l_lan2+1;
    curr2=l_lan+1;
    for i=1:l_lan
        rot=trans_ind(1,tran(i));
        shx=trans_ind(2,tran(i));
        shy=trans_ind(3,tran(i));
        strain{ii}(i,:)=squeeze(newimgs(cc2(lan(i)),tran(i),:));
        land3{ii}{i}=curr3:(curr3+length(cindex{cc2(lan(i))})-1);
        for k=cindex{cc2(lan(i))}
            if rot~=0
                tmp=imrotate(reshape(ntrain(k,:),sq,sq),rot,'crop');
            else
                tmp=reshape(ntrain(k,:),sq,sq);
            end
            if shx~=0 || shy~=0
                mat=[1,shx,0;shy,1+shx*shy,0;0,0,1];
                tform = maketform('affine',mat);
                tmp = imtransform(tmp,tform);
            end
            strain{ii}(curr3,:)=f_bb2(tmp,sq)';
            curr3=curr3+1;
        end
        %{
        %}
            land2{ii}{i}=curr2:curr2+length(cindex2{lan(i)})-1;
        for jj=1:length(cindex2{lan(i)})
            j=cindex2{lan(i)}(jj);        
            
            rot=trans_ind(1,tran(i))+trans_ind(1,tindex2{lan(i)}(jj));
            shx=trans_ind(2,tran(i))+trans_ind(2,tindex2{lan(i)}(jj));
            shy=trans_ind(3,tran(i))+trans_ind(3,tindex2{lan(i)}(jj));

            ind=find(trans_s==(rot+shx+4*shy));
            if(isempty(ind))
                tmp=imrotate(reshape(ntrain(cc(j),:),sq,sq),rot,'crop');
                mat=[1,shx,0;shy,1+shx*shy,0;0,0,1];
                tform = maketform('affine',mat);
                tmp = imtransform(tmp,tform);
                strain{ii}(curr2,:)=f_bb2(tmp,sq)';            
            else
                strain{ii}(curr2,:)=squeeze(newimgs(j,ind,:));
            end
            land3{ii}{curr2}=curr3:(curr3+length(cindex{j})-1);
            curr2=curr2+1;
            
            for k=cindex{j}
                if rot~=0
                    tmp=imrotate(reshape(ntrain(k,:),sq,sq),rot,'crop');
                else
                    tmp=reshape(ntrain(k,:),sq,sq);
                end
                if shx~=0 || shy~=0
                    mat=[1,shx,0;shy,1+shx*shy,0;0,0,1];
                    tform = maketform('affine',mat);
                    tmp = imtransform(tmp,tform);
                end
                strain{ii}(curr3,:)=f_bb2(tmp,sq)';
                curr3=curr3+1;
            end
            %{
            %}
        end
    end

    dis{ii}=IDM8(strain{ii}(1:l_lan,:)',strain{ii}');
    aligned(ii,:)=strain{ii}(1,:);
end
%sum(strain{})
%see2(track{1},'strain','haha');

%5) train dist matrix

eval(['save dis' num2str(digit) '  dis strain ']);


%6) align test images
timg_a=cell(1,10);
trans_a=cell(1,10);
dist_a=cell(1,10);

for tt=0:9
timg=eval(['test' num2str(tt)]);

newtimgs=zeros([size(timg,1),ll,size(timg,2)]);
timg_a{tt+1}=zeros(size(timg));
for i=1:size(timg,1)
%all angles
    tmp=reshape(timg(i,:),sq,sq);
    for j=1:lr
        tmpp=imrotate(tmp,rot_set(j),'crop');
        for k=1:ls
            for kk=1:ls
                mat=[1,shear_set(k),0;shear_set(kk),1+shear_set(k)*shear_set(kk),0;0,0,1];
                tform = maketform('affine',mat);
                tmp2 = imtransform(tmpp,tform);  
                newtimgs(i,(j-1)*ls*ls+(k-1)*ls+kk,:)=f_bb2(tmp2,sq)';
            end
        end
    end
end

[trans,ind,dis]=Align3(aligned,newtimgs,2,1);
for i=1:size(timg,1)
    timg_a{tt+1}(i,:)=squeeze(newtimgs(i,trans(i),:));
end
trans_a{tt+1}=trans;
dist_a{tt+1}=dis;
end

eval(['save a_test' num2str(tt) '  timg_a trans_a dist_a']);


end

%{
%}
end



