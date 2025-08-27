ALTER TABLE dbo.claims
Alter column claim_amount decimal(18,2);

ALTER TABLE dbo.policies
Alter column premium_amount decimal(18,2);

ALTER TABLE dbo.payments
Alter column amount_paid decimal(18,2);

-- Check the tables

Select TOP(10)* from dbo.claims;
Select top(10)* from dbo.policies;
Select top(10)* from dbo.payments;
Select top(10)* from dbo.policyholders;

-- Data Validation
--1.
Select policyholder_id, count(*) AS NumPolicies
From policies
group by policyholder_id;

--2.
Select claim_id, claim_type,policy_type
from dbo.claims c
join dbo.policies p on c.policy_id=p.policy_id
where not (
(c.claim_type ='Theft' And p.policy_type='Motor')
or (c.claim_type = 'Accident' and p.policy_type in ('Motor', 'Property'))
or (c.claim_type = 'Medical' And p.policy_type = 'Health')
);

-- Missing values

Select * From dbo.policyholders
Where Date_of_Birth is null or name is null;

-- Negative or zero premiums/claims

Select * from dbo.claims
where claim_amount <= 0;

Select * from  dbo.payments
where amount_paid <= 0;

Select * from dbo.policies
where premium_amount <= 0;

-- Invalid dates (Join date before age 21)

Select policyholder_id, Date_of_birth, join_date
from dbo.policyholders
where DATEDIFF(year, Date_of_birth, join_date)<21

-- Payments larger than claim
Select payment_id, c.claim_id, claim_amount, sum(amount_paid) as TotalPaid
from dbo.payments p
join dbo.claims c on p.claim_id=c.claim_id
group by p.payment_id, c.claim_id, c.claim_amount
having sum(p.amount_paid) > c.claim_amount;

-- Total premiums per policytype

Select p.policy_type,count(c.claim_id) As TotalClaims, 
sum(c.claim_amount) as total_claim_amount
from dbo.policies p
join dbo.claims c on p.policy_id=c.policy_id
group by p.policy_type;


-- top 5 policyholders by payments
Select top 5 ph.name, sum(py.amount_paid) As total_paid
from dbo.policyholders ph
join dbo.policies p on ph.policyholder_id=p.policyholder_id
join dbo.claims c on c.policy_id= p.policy_id
join dbo.payments py on c.claim_id=py.claim_id
group by ph.name
order by total_paid desc;

-- view: loss ratio by policy type 

Create view LossRatio As
Select p.policy_type, sum(py.amount_paid)/sum(p.premium_amount) As loss_ratio
from dbo.policies p
join dbo.claims c on p.policy_id=c.policy_id
join dbo.payments py on py.claim_id=c.claim_id
group by p.policy_type;
 
select * from LossRatio

--top n claimants
create procedure GetTopClaimants( @top INT)
AS 
begin 
Select top(@top) ph.name, sum(py.amount_paid) As total_paid
from dbo.policyholders ph
join dbo.policies p on ph.policyholder_id=p.policyholder_id
join dbo.claims c on p.policy_id=c.policy_id
join dbo.payments py on c.claim_id=py.claim_id
group by ph.Name
order by total_paid desc
End;


Exec GetTopClaimants @top=5