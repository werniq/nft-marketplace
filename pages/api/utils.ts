import { NextApiRequest, NextApiResponse } from "next";
import { withIronSession, Session } from "next-iron-session";
import contract from "../../public/contracts/NftMarket.json"
import { ethers } from 'ethers';
import { NftMarketContract } from "@_types/nftMarketContract";
import * as util from "ethereumjs-util";

const NETWORKS = {
    "5777": "Ganache"
}

type NETWORK = typeof NETWORKS;

const targetNetwork = process.env.NEXT_PUBLIC_NETWORK_ID as keyof NETWORK;
const abi = contract.abi;

export const contractAddress = contract["networks"][targetNetwork]["address"];

export const apiKey = process.env.PINATA_API_KEY as string;
export const secretKey = process.env.PINATA_SECRET_KEY as string;


export function withSession(handler: any) { 
    return withIronSession(handler, {
        password: process.env.SECRET_COOKIE_PASSWORD as string, 
        cookieName: "nft-auth-session",
        cookieOptions: {
            secure: process.env.NODE_ENV === "production" ? true : false
        }
    })
}


export const addressCheckMiddleware = async (request: NextApiRequest & {session: Session}, response: NextApiResponse) => {
    return new Promise((resolve, reject) => {
        const message = request.session.get("message-session");
        // Server side provider
        const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:7545");
        const contraсt = new ethers.Contract(
            contractAddress,
            abi,
            provider
        ) as unknown as NftMarketContract;
        // contract Address
        // abi 
        // provider

        let nonce: string | Buffer = 
        "\x19Ethereum Signed Message:\n" +
        JSON.stringify(message).length +
        JSON.stringify(message)

        nonce = util.keccak(Buffer.from(nonce, "utf-8"));
        const { v, r, s } = util.fromRpcSig(request.body.signature);
        const pubKey = util.ecrecover(util.toBuffer(nonce), v, r, s);
        const addrBuffer = util.pubToAddress(pubKey);
        const address = util.bufferToHex(addrBuffer);
        
        if (address === request.body.address) {
            resolve("Correct Address");
        } else {
            reject("Wrong Address");
        }
    })
}