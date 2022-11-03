import { CryptoHookFactory } from "@_types/hooks";
import { initScriptLoader } from "next/script";
import { useEffect } from "react";
import useSWR from "swr";



type UseAccountResponse = {
    connect: () => void;
    isLoading: boolean;
    isInstalled: boolean;
}
type AccountHookFactory = CryptoHookFactory<string, UseAccountResponse>

export type UseAccountHook = ReturnType<AccountHookFactory>


export const hookFactory: AccountHookFactory = ({ provider, ethereum, isLoading }) => () => {

    // deps -> provider, ethereum, contract (web3State)
    // connect Metamask function

    const {data, mutate, isValidating, ...swr} = useSWR(
        provider ? "web3/useAccount": null,
        async () => {

            const accounts = await provider!.listAccounts();
            const account = accounts[0];


            if (!account) {
                throw "Can not retrieve account! Connect to web3 wallet."
            }

            return account;
        
        
        }, {
            revalidateOnFocus: false
        }
    )


    useEffect(() => {
        ethereum?.on("accountsChanged", handleAccountsChanged);
        return () => {
            ethereum?.removeListener("accountsChanged", handleAccountsChanged)
        }
    })


    const handleAccountsChanged = (...args: unknown[]) => {
        const accounts = args[0] as string[];
        if (accounts.length === 0) {
            console.error("Please connect Web3 wallet");
        } else if (accounts[0] !== data) {
            mutate(accounts[0]);
        }
    }


    const connect = async () => {
        try {                
            ethereum?.request({ method: "eth_requestAccounts" });
        } catch(e) {
            console.error(e);
        }
    }

    return {
        ...swr,
        data,
        isValidating,
        isLoading: isLoading || isValidating,
        isInstalled: ethereum?.isMetaMask || false,
        mutate,
        connect
    };
}


// export const useAccount = hookFactory({ ethereum: undefined, provider: undefined });