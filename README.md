# KipuBank

---
### 🔹 Casos de uso
- Funciones que manejan **transferencias de tokens** (ej: `withdraw`, `deposit`).
- Funciones que modifican **estados críticos** (ej: balances, contadores).
- Cualquier función donde una llamada externa pueda reingresar al contrato antes de finalizar.

---
## 🚀 Despliegue

### Requisitos previos
**Entorno de desarrollo**:
   - [Remix IDE](https://remix.ethereum.org/) (recomendado para pruebas rápidas).

### Pasos para desplegar
#### Opción 1: Usando Remix IDE

1. **Abrir Remix** y clonar el proyecto

2. **Compilar:**
    - Seleccionar el compilador Solidity 0.8.30+.
    - Hacer clic en "Compile".

3. **Desplegar KipuBank.sol:**
    - Ir a la pestaña "Deploy & Run".
    - Seleccionar el entorno (ej: Injected Web3 para MetaMask o JavaScript VM para pruebas locales).
    - Ingresar bankCap
    - Hacer clic en "Deploy".
    - Copiar address del contrato

4. **Publicar en testnet**
    - Ingresar a https://sepolia.etherscan.io/
    - Buscar address del contrato
    - En Contracts, completar Verify & Publish

