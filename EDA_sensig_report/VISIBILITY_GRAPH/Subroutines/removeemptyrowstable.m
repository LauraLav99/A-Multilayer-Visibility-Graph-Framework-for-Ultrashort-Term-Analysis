function Tw1=removeemptyrowstable(Tw1)
indx=cellfun(@isempty,Tw1.(1));
Tw1(indx,:)=[];
end