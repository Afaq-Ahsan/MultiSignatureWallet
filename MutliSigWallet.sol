// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiSignatureWallet{

    mapping(address => bool) public isOwners;
    address[] public OwnersArray;
    uint public numOfConfirmationsRequired;

    struct Transaction{
        address to;
        uint value;
        bytes data;
        uint numConfirmations;
        bool executed;}

    mapping(uint=>mapping(address=>bool)) public isconfirmed;

    Transaction[] transactionArray;

modifier onlyOwner(){
    require(isOwners[msg.sender],"only owner can call this function");
    _;}
modifier txExist(uint _txIndex){
    require(_txIndex <= transactionArray.length,"transaction is not exist");
    _;}
modifier notExecuted(uint _txIndex) {
    require(!transactionArray[_txIndex].executed,"transaction already executed");
    _;}   
modifier notConfirmed(uint _txIndex){
    require(!isconfirmed[_txIndex][msg.sender],"transaction is confirmed");
    _;}


event SubmitTransactionEvent(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
  event Deposit(address indexed sender, uint amount, uint balance);
  event ConfirmTransaction(address indexed owner, uint indexed txIndex);
  event ExecuteTransactionEvent(address indexed owner, uint indexed txIndex);
  event revokeconfirmationEvent(address indexed owner, uint indexed txIndex);

constructor(address[] memory _owners,uint _numOfConfirmationsRequired){

    require(_owners.length >0,"you must need to have owners");
    require(_numOfConfirmationsRequired > 0 && _numOfConfirmationsRequired <=_owners.length,
    "kindly enter number of confirmations properly");
     for(uint i=0;i<=_owners.length;i++){
        address OWNER = _owners[i];
        require(OWNER!=address(0),"owner can not b a zero address");
        require(!isOwners[OWNER],"you cannot make same address as owner");
        isOwners[OWNER] = true;
        OwnersArray.push(OWNER);
     }
     numOfConfirmationsRequired = _numOfConfirmationsRequired;

}

receive() external payable{
    emit Deposit(msg.sender, msg.value, address(this).balance);
}

function SubmitTransaction(address _to,uint _value,bytes memory _data)public onlyOwner{

      uint txIndex = transactionArray.length;
      transactionArray.push(
          Transaction({
              to:_to,
              value:_value,
              data:_data,
              numConfirmations:0,
              executed:false 
          }));

          emit SubmitTransactionEvent(msg.sender, txIndex, _to, _value, _data);
}

function confirmTransaction(uint _TxIndex)public 
    onlyOwner txExist(_TxIndex) notExecuted(_TxIndex) notConfirmed(_TxIndex){
    Transaction storage transaction = transactionArray[_TxIndex];
    transaction.numConfirmations+=1;
    isconfirmed[_TxIndex][msg.sender]=true;
    emit ConfirmTransaction(msg.sender, _TxIndex);
}

function ExecuteTransaction(uint _TxIndex) public onlyOwner txExist(_TxIndex) notExecuted(_TxIndex) {
    Transaction storage transaction = transactionArray[_TxIndex];
    require(transaction.numConfirmations >= numOfConfirmationsRequired,
    "you dont have enough confirmations");
    transaction.executed = true;
    (bool success,) = transaction.to.call{value:transaction.value}(transaction.data);
    require(success,"transaction is not executed");
    emit ExecuteTransactionEvent(msg.sender, _TxIndex);
}

function RevokeConfirmation(uint _TxIndex) public onlyOwner txExist(_TxIndex) notExecuted(_TxIndex){
    Transaction storage transaction = transactionArray[_TxIndex];
    require(isconfirmed[_TxIndex][msg.sender],"transaction is already not confirmed yet");
    transaction.numConfirmations -=1;
    isconfirmed[_TxIndex][msg.sender] = false;
    emit revokeconfirmationEvent(msg.sender, _TxIndex);
}
function getOwners() public view returns(address[] memory){
    return OwnersArray;
}

function getTransactionCount()public view returns(uint){
    return transactionArray.length;
}
function getTransaction(uint _TxIndex) public view returns( 
    address to,
    uint value,
    bytes memory data,
    bool executed,
    uint numConfirmations){

Transaction storage transaction = transactionArray[_TxIndex];

return(
    transaction.to,
    transaction.value,
    transaction.data,
    transaction.executed,
    transaction.numConfirmations
);
}


}