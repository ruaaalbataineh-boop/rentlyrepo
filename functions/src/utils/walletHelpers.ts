import { getFirestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

const db = getFirestore();

export type WalletRef = FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>;

export async function requireWallets(uid: string): Promise<{
  user: WalletRef;
  holding: WalletRef;
}> {
  const ws = await db.collection("wallets").where("userId","==",uid).get();

  let user: WalletRef | null = null;
  let holding: WalletRef | null = null;

  ws.forEach(d=>{
    const t = d.data().type;
    if(t==="USER") user = d.ref as WalletRef;
    if(t==="HOLDING") holding = d.ref as WalletRef;
  });

  if(!user || !holding)
    throw new HttpsError("failed-precondition",`Wallet missing for ${uid}`);

  return { user, holding };
}
