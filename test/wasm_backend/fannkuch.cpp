/*
 * The Computer Language Benchmarks Game
 * http://shootout.alioth.debian.org/
 *
 * Contributed by Eckehard Berns
 * Based on code by Heiner Marxen
 * and the ATS version by Hongwei Xi
 *
 * Modified for emscripten by azakai
 */

#include <emscripten.h>

struct worker_args {
   int i, n;
   struct worker_args *next;
};

int A[12];
int B[12];
int C[12];

int
fannkuch_worker(void *_arg)
{
   struct worker_args *args = (worker_args*)_arg;
   int *perm1, *count, *perm;
   int maxflips, flips, i, n, r, j, k, tmp;

   maxflips = 0;
   n = args->n;
   perm1 = (int*)A;
   perm = (int*)B;
   count = (int*)C;
   for (i = 0; i < n; i++)
      perm1[i] = i;
   perm1[args->i] = n - 1;
   perm1[n - 1] = args->i;
   r = n;

   for (;;) {
      for (; r > 1; r--)
         count[r - 1] = r;
      if (perm1[0] != 0 && perm1[n - 1] != n - 1) {
         for (i = 0; i < n; i++)
            perm[i] = perm1[i];
         flips = 0;
         k = perm[0];
         do {
            for (i = 1, j = k - 1; i < j; i++, j--) {
               tmp = perm[i];
               perm[i] = perm[j];
               perm[j] = tmp;
            }
            flips++;
            tmp = perm[k];
            perm[k] = k;
            k = tmp;
         } while (k);
         if (maxflips < flips)
            maxflips = flips;
      }
      for (;;) {
         if (r >= n - 1) {
            return maxflips;
         }

         {
            int p0 = perm1[0];
            for (i = 0; i < r; i++)
               perm1[i] = perm1[i + 1];
            perm1[i] = p0;
         }
         if (--count[r] > 0)
            break;
         r++;
      }
   }
}

worker_args D[12];
int E[12];
int F[12];

static int
fannkuch(int n)
{
   struct worker_args *args, *targs;
   int showmax = 30;
   int *perm1, *count, i, r, maxflips, flips;

   args = 0;
   for (i = 0; i < n - 1; i++) {
      targs = &D[i];
      targs->i = i;
      targs->n = n;
      targs->next = args;
      args = targs;
   }

   perm1 = (int*)E;
   count = (int*)F;

   for (i = 0; i < n; i++)
      perm1[i] = i;

   r = n;
   for (;;) {
      if (showmax) {
         // for (i = 0; i < n; i++)
         //    printf("%d", perm1[i] + 1);
         // printf("\n");
         showmax--;
      } else
         goto cleanup;

      for (; r > 1; r--)
         count[r - 1] = r;

      for (;;) {
         if (r == n)
            goto cleanup;
         {
            int p0 = perm1[0];
            for (i = 0; i < r; i++)
               perm1[i] = perm1[i + 1];
            perm1[i] = p0;
         }
         if (--count[r] > 0)
            break;

         r++;
      }
   }

    cleanup:
   maxflips = 0;
   while (args != 0) {
      flips = (int)fannkuch_worker(args);
      if (maxflips < flips)
         maxflips = flips;
      targs = args;
      args = args->next;
   }
   return maxflips;
}

int
main(int argc, char **argv)
{
          int n;
          int arg = argc > 1 ? argv[1][0] - '0' : 6;
          switch(arg) {
            case 0: return 0; break;
            case 1: n = 9; break;
            case 2: n = 10; break;
            case 3: n = 11; break;
            case 4: n = 11; break;
            case 5: n = 12; break;
            case 6: n = 7; break;
            default: return -1;
          }

   if (n < 1) {
      return -2;
   }

   volatile int *x = (volatile int*)4;

   *x = n;
   EM_ASM({
     Module.print('n = ' + HEAP32[4>>2]);
   });

   *x = fannkuch(n);
   EM_ASM({
     Module.print('fannkuch(n) = ' + HEAP32[4>>2]);
   });
   return 0;
}
