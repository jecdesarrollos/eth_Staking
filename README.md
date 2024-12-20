# eth_Staking
Eth Kipu Staking Contract

Jorge Enrique Cabrera Curso Ashitaka 2024 Buenos Aires

Publicado y verificado en Sepolia testnet

Contract creator: 0x60b1D95b9DF21e19DdAf88Ef11B74Bc534C0a5CE

Contract Staking address : 0x047dFbADF22fDB2A835d92220c8cd923bb88Acf1

Contract Token address: 0x6061f7e05999e57B2DA7A58b119b426B5CA9E76E

Test:
A los fines del test lo realicé con Foundry se ha realizado mediante  forge test
simulando un token (MockERC20) al efecto .

Se adjuntan:
IJER20.sol (Interface del Token)
JERC20.sol (Token publicado en Sepolia)
IStaking.sol (Interface de Contrato publicado en Sepolia)
Staking.sol (Contrato publicado en Sepolia)

StakingTest.sol (Archivo de test en foundry )
testResultado.txt (Resultados del test pasados)
readme.md (Este archivo)

Especificaciones del ejercicio:

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// El contrato tiene que aceptar el staking de los usuarios
// Para un determinado IERC20, no hace falta crear un token propio
// El flujo sería:
// El usuario stakea una cierta cantidad de tokens en el contrato
// Puede stakear por 1 año , 2 o 3. Y los respectivos rewards serian 25% extra, 50% extra y 75% extra
// Si alguien quiere retirar antes de tiempo, se le penaliza recibiendiendo solo lo que stakearon
// Para facilitar el desarrollo, nadie puede stakear menos de 1 año. Y no reciben rewards si no llegan a 1 año
// Cuando alguien hace unStake automáticamente se le pagan las rewards si corresponden
// Si alguien llama a claimReward, podrá retirar las rewards que le correspondan pero el staked seguirá generando rewards
// Recordad que suponemos que el owner tiene dinero infinito y puede depositar suficientes tokens para que cuando la gente haga unstake,
// siempre haya suficiente liquidez
// Será necesario entregar el contrato con el natspec completo y los unit tests.

// Consejo, crear una función internal que calcule las rewards de un usuario dado que es lógica compartida tanto en unStake como en claimReward

interface IStaking {
  /*///////////////////////////////////////////////////////////////
                              STRUCTS                            
  //////////////////////////////////////////////////////////////*/

  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /*///////////////////////////////////////////////////////////////
                              VIEWS
  //////////////////////////////////////////////////////////////*/

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/
  
/**
   * @notice Stake a certain amount of tokens for a certain duration
   * @param _amount The amount of tokens to stake
   * @param _duration The duration of the stake
   */
  function stake(uint256 _amount, uint256 _duration) external;

  /**
   * @notice Unstake the tokens
   * @dev If the user unstakes before the duration, they will only get the staked amount
   * If the user unstakes after the duration, they will get the staked amount plus the rewards
   */
  function unStake() external;

  /**
   * @notice Claim the rewards
   */
  function claimReward() external;

  /**
   * @notice Get the total amount of tokens staked
   * @param _amount The amount of tokens to stake
   */
  function ownerDeposit(uint256 _amount) external;
}
