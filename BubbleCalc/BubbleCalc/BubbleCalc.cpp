#include <iostream>
using namespace std;

/*
    This is a simple program that makes a correspondence table between Bubble Page and Bubble Position
*/

int main()
{
    int bubblePage = 0;
    int bubblePosition = 0;
    int bubblePositionArray[2053] = { 0 };

    cout << "BubblePageCalc" << endl;

    bubblePage = 401;
    bubblePosition = 9;
    //by observation 0x191(=401)page is position 9
    //FBM54DB can store 2053 pages max

    for (int i = 0; i < 2053; i++)
    {
        if (bubblePage < 2053 && bubblePosition < 2053)
        {
            //둘중하나선택
            //cout << "Page: " << bubblePage << " = " << bubblePosition << endl;
            bubblePositionArray[bubblePosition] = bubblePage;

            bubblePage = bubblePage + 1;
            bubblePosition = bubblePosition + 704;
        }
        else
        {
            while (bubblePage >= 2053)
            {
                bubblePage = bubblePage - 2053;
            }
            while (bubblePosition >= 2053)
            {
                bubblePosition = bubblePosition - 2053;
            }

            //둘중하나선택
            //cout << "Page: " << bubblePage << " = " << bubblePosition << endl;
            bubblePositionArray[bubblePosition] = bubblePage;

            bubblePage = bubblePage + 1;
            bubblePosition = bubblePosition + 704;
        }
    }

    
    for (int i = 0; i < 2053; i++)
    {
        cout << "	    12'd" << i << ": current_page_output <= 12'd" << bubblePositionArray[i] << ";" << endl;
    }
    for (int i = 2053; i < 4096; i++)
    {
        cout << "	    12'd" << i << ": current_page_output <= 12'd" << 4095 << ";" << endl;
    }
    
    return 0;
}
