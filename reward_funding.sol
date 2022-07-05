//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//importing ERC721 contract 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";


//contract for crowdfunding

contract Funding is ERC721{
    //uint public fundAmt; 
    mapping(address => uint) investors;                   // investors history
    mapping(address => bool) aleardyInvestor;             // sotres aleardy investors history
    address payable manager;
    uint public totalAmt;
    uint public noOfInvestors;
    uint public goalAmt;
    uint public goalTime;
    uint endTime;
    uint startTime;
    mapping(address => uint) nftHolders;
    mapping(address => bool) claims; // history fo the number of people claimed
    uint public tokenId;


    //events
    event invested(address from,uint value);
    event toManager(address from,address to,uint value);
    event toInvsetors(address from,address to,uint value);
    
    // function modifier
     modifier checkInvestor{
        require(manager!=msg.sender); 
        require(msg.value > 0 wei,"not enough funds"); 
        require(block.timestamp < endTime,"funding pool expired");   
        require(amntRequired() > 0 ,"funding goal reached"); 
        _;
     }

     //function modifier fund to manger
     modifier fundToManager{
        require(block.timestamp > endTime && totalAmt >= goalAmt); 
        require(investors[msg.sender] <= 0,"claimed aleardy");
        _;
     }

     //function modifier funds back to investors
     modifier fundToInvestors{
        require(block.timestamp > endTime && totalAmt < goalAmt);
        _;
     }

    //constructor for intializing manager 
    //goal time in days
    constructor(uint _amt,uint _time) ERC721("Mini project","MN"){
        goalAmt=_amt;
        goalTime=_time;
        endTime=block.timestamp + (((goalTime*25)*60)*60);  // time in days as input    
        manager=payable(msg.sender);                        //contract ---> deploy address 
    }

    //getting fund amount to contract and checking for the conditions to met
    //the first and last person who is investing can invest more than required
    function toGetFunds() external payable checkInvestor{
        if(!aleardyInvestor[msg.sender]){                 // checks for new investors
            investors[msg.sender]=msg.value;
            totalAmt+=msg.value;
            noOfInvestors+=1;                             //number of investors here 
            aleardyInvestor[msg.sender]=true;  // adding him in the investors mapping
            claims[msg.sender]=true;           // this for the condition checking in nft claims
        }
        else{                                             // aleardy investors here works
            investors[msg.sender]=msg.value+investors[msg.sender];
            totalAmt+=msg.value;
        }
        emit invested(msg.sender,msg.value);
    }

    //there are two outcomes for our project
    // 1.successful funding   2.failed funding 
   
    //1.If successful funding 
    // so funds will transfer to the fund raiser
    function FundsToManager() external payable fundToManager{
        manager.transfer(address(this).balance);
        emit toManager(address(this),manager,address(this).balance);
    }

    //2.If the funding is failed
    //here refunding the funds to the investors if funding goal is not reached
    function reFundingToInvestors() external payable fundToInvestors{
        payable(msg.sender).transfer(investors[msg.sender]);
        emit toInvsetors(address(this),msg.sender,investors[msg.sender]);
        investors[msg.sender]=0;
    }


    //to check the amount required
    function amntRequired()internal view returns(uint a){
        if(totalAmt < goalAmt){
            return (goalAmt-totalAmt);
        }
        return 0;
    }

    //this function is to mint the number of tokens , if the successful funding is happend
    function mintReward()external{
        require(!(!claims[msg.sender]),"your not investor");
        require(tokenId < noOfInvestors,"minting completed");
        //require()
        _mint(msg.sender,tokenId);
        claims[msg.sender]=false;
        tokenId+=1;
    }

}

