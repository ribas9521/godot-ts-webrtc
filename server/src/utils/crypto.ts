import { v4 as uuidv4 } from "uuid";

export const generateId = () => {
  return Number(
    BigInt("0x" + uuidv4().replace(/-/g, "") + new Date().getDate())
      .toString()
      .slice(-9)
  );
};
