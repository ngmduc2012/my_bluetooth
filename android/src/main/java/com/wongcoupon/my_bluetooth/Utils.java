package com.wongcoupon.my_bluetooth;

import android.util.Log;

public class Utils {


    private static final String TAG = "[MyBluetooth-Android]";

    void log(String message )
    {
        Log.d(TAG, message);
    }

    public String getLastTwoCharacters(String str) {
        if (str == null || str.length() < 2) {
            return str;
        }
        return str.substring(str.length() - 2);
    }

    // Learn more ASCII: https://www.cs.cmu.edu/~pattis/15-1XX/common/handouts/ascii.html
    static String convertAsciiToString(int[] asciiValues) {
        StringBuilder sb = new StringBuilder();
        for (int value : asciiValues) {
            sb.append((char) value);
        }
        return sb.toString();
    }

     static String printByteArray(byte[] byteArray) {
        StringBuilder sb = new StringBuilder();
        sb.append("[");

        for (int i = 0; i < byteArray.length; i++) {
            sb.append("0x").append(String.format("%02X", byteArray[i])); // Định dạng từng phần tử
            if (i < byteArray.length - 1) {
                sb.append(", "); // Thêm dấu phẩy giữa các phần tử
            }
        }

        sb.append("]");
        return sb.toString(); // In ra kết quả
    }

    // Hàm chuyển đổi byte[] thành Integer[]
    static Integer[] convertByteArrayToIntArray(byte[] byteArray) {
        Integer[] intArray = new Integer[byteArray.length]; // Tạo mảng Integer[]
        for (int i = 0; i < byteArray.length; i++) {
            intArray[i] = (int) byteArray[i]; // Chuyển đổi từng byte thành Integer
        }
        return intArray; // Trả về mảng Integer[]
    }
}
